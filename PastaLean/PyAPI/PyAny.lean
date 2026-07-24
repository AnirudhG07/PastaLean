import PastaLean.PyAPI.PyPrint
import PastaLean.PyAPI.CommonProtocols.Truthy
import PastaLean.PyAPI.CommonProtocols.GetItem
import PastaLean.PyAPI.CommonProtocols.SetItem
import PastaLean.PyAPI.CommonProtocols.Length
import PastaLean.PyAPI.CommonProtocols.Iterable
import PastaLean.PyAPI.CommonProtocols.IsNone
import PastaLean.PyAPI.Operators
import PastaLean.PyAPI.Builtins.Casting

/-!
# `PyAny` — the dynamic-value fallback

When type inference cannot give a value a single Lean type — a variable that is an `int` on one path
and a `str` on another, a function that returns different types per branch — the value is boxed as a
`PyAny`. Every Python value maps into `PyAny`, so a boxed slot always type-checks; the cost is
that a boxed value is not provable (it is not a commutative ring), which is why boxing is a last
resort the code generator warns about.

Boxing is automatic at the boundary: a `CoeTail` instance means `return 1` and `return "neg"` in the
same function both coerce to `PyAny` with no explicit wrapper.
-/

namespace PastaLean

/-- A boxed Python value: whatever a slot could not be given a single static type. -/
inductive PyAny where
  | int   (n : Int)
  | bool  (b : Bool)
  | str   (s : String)
  | float (q : Rat)
  | list  (xs : List PyAny)
  | none
  deriving Repr

/-- The canonical empty/default boxed value. Used to initialize a hoisted `let mut` binding for a
variable Python assigns only inside a block (`if`/`try`) — Lean has no such leak-out, so codegen
pre-declares the variable before the block. `none` (Python `None`) is the honest empty; it does not
faithfully model `UnboundLocalError`, which the linter flags separately. -/
def emptyPyAny : PyAny := .none

/-- Default a `PyAny` to `emptyPyAny` (Python `None`), not `int 0` (the derived first-constructor
default), so a hoisted dynamic binding reads as "unset" rather than a spurious zero. -/
instance : Inhabited PyAny := ⟨emptyPyAny⟩

namespace PyAny

/-- Python `str()` of a boxed value; `repr` is the form shown *inside* a container (strings quoted). -/
partial def toStr (repr : Bool) : PyAny → String
  | .int n   => toString n
  | .bool b  => if b then "True" else "False"
  | .str s   => if repr then "'" ++ s ++ "'" else s
  | .float q => toString (Rat.toFloat q)
  | .none    => "None"
  | .list xs => "[" ++ String.intercalate ", " (xs.map (toStr true)) ++ "]"

end PyAny

/-- Box a value of a known type into `PyAny`. -/
class PyToValue (α : Type) where
  toValue : α → PyAny

export PyToValue (toValue)

instance : PyToValue PyAny where toValue := id
instance : PyToValue Int     where toValue := .int
instance : PyToValue Nat     where toValue n := .int n
instance : PyToValue Bool    where toValue := .bool
instance : PyToValue String  where toValue := .str
instance : PyToValue Char    where toValue c := .str (String.singleton c)
instance : PyToValue Rat     where toValue := .float
instance : PyToValue Unit    where toValue _ := .none
instance {α : Type} [PyToValue α] : PyToValue (List α)   where toValue xs := .list (xs.map toValue)
instance {α : Type} [PyToValue α] : PyToValue (Option α) where
  toValue | some x => toValue x | none => .none

/-- Automatic boxing at a boundary: a branch of a known type coerces to `PyAny`, so the two arms
of `if c then 1 else "neg"` unify at `PyAny` with no explicit wrapper. Concrete source types only —
a generic `CoeTail α PyAny` has no synthesization order (the source `α` is unconstrained). -/
instance : CoeTail Int PyAny    where coe := .int
instance : CoeTail Nat PyAny    where coe n := .int n
instance : CoeTail Bool PyAny   where coe := .bool
instance : CoeTail String PyAny where coe := .str
instance : CoeTail Char PyAny   where coe c := .str (String.singleton c)
instance : CoeTail Rat PyAny    where coe := .float
instance : CoeTail (List PyAny) PyAny where coe := .list
instance : CoeTail (List Int) PyAny     where coe xs := .list (xs.map .int)
instance : CoeTail (List String) PyAny  where coe xs := .list (xs.map .str)

-- Numerals are polymorphic via `OfNat`, not coercion, so a bare `0`/`5` in a boxed position needs
-- these (codegen usually emits typed literals like `(0 : Int)`, which coerce, but not always).
instance (n : Nat) : OfNat PyAny n where ofNat := .int n
instance : Neg PyAny where neg | .int n => .int (-n) | .float q => .float (-q) | v => v

/-! ### Dynamic arithmetic — dispatch on the runtime tag

This is what makes a boxed polymorphic function like `def add(a, b): return a + b` run at *both* `int`
and `str`: `a +ₚ b` is one definition that inspects the constructors at runtime. Same-type operands
combine as Python does (`int+int`, `str++str`, `list++list`); numeric operands promote to `float`;
`bool` counts as `0`/`1`. A genuine mismatch (`1 + "a"`) yields `none` rather than raising — a soft
failure that keeps the operation total. -/

namespace PyAny

def asNum : PyAny → Option (Sum Int Rat)
  | .int n => some (.inl n)
  | .bool b => some (.inl (if b then 1 else 0))
  | .float q => some (.inr q)
  | _ => .none

/-- Apply integer/rational ops to two numeric boxes, promoting to `float` if either is a float. -/
def numBinop (fi : Int → Int → Int) (fq : Rat → Rat → Rat) (a b : PyAny) : Option PyAny :=
  match asNum a, asNum b with
  | some (.inl x), some (.inl y) => some (.int (fi x y))
  | some x, some y =>
      let toRat : Sum Int Rat → Rat := fun | .inl n => (n : Rat) | .inr q => q
      some (.float (fq (toRat x) (toRat y)))
  | _, _ => .none

def add : PyAny → PyAny → PyAny
  | .str a, .str b => .str (a ++ b)
  | .list a, .list b => .list (a ++ b)
  | a, b => (numBinop (· + ·) (· + ·) a b).getD .none

def sub (a b : PyAny) : PyAny := (numBinop (· - ·) (· - ·) a b).getD .none
def mul : PyAny → PyAny → PyAny
  | .str a, .int n => .str (String.join (List.replicate n.toNat a))
  | .int n, .str a => .str (String.join (List.replicate n.toNat a))
  | a, b => (numBinop (· * ·) (· * ·) a b).getD .none

private def toRat : Sum Int Rat → Rat := fun | .inl n => (n : Rat) | .inr q => q

/-- Python `/` is always true division → `float`. -/
def div (a b : PyAny) : PyAny :=
  match asNum a, asNum b with
  | some x, some y => let d := toRat y; if d == 0 then .none else .float (toRat x / d)
  | _, _ => .none

/-- Python `//`: `int//int` stays `int` (floored), else a floored `float`. -/
def floordiv (a b : PyAny) : PyAny :=
  match asNum a, asNum b with
  | some (.inl x), some (.inl y) => if y == 0 then .none else .int (pyFloorDiv x y)
  | some x, some y => let d := toRat y; if d == 0 then .none else .float ((Rat.floor (toRat x / d) : Int) : Rat)
  | _, _ => .none

/-- Python `%`: `int%int` stays `int`, else float modulo `a - b*⌊a/b⌋`. -/
def mod (a b : PyAny) : PyAny :=
  match asNum a, asNum b with
  | some (.inl x), some (.inl y) => if y == 0 then .none else .int (pyMod x y)
  | some x, some y =>
      let xr := toRat x; let yr := toRat y
      if yr == 0 then .none else .float (xr - yr * ((Rat.floor (xr / yr) : Int) : Rat))
  | _, _ => .none

/-- Python `**`: `int**(≥0)` stays `int`; an integer exponent otherwise gives a `float`; a fractional
exponent is transcendental (soft-`none`). -/
def pow (a b : PyAny) : PyAny :=
  match asNum a, asNum b with
  | some (.inl x), some (.inl y) => if y ≥ 0 then .int (x ^ y.toNat) else .float ((toRat (.inl x)) ^ y)
  | some x, some (.inl y) => .float ((toRat x) ^ y)
  | _, _ => .none

/-- The integer value of a boxed `int`/`bool`, for the integer-only bitwise/shift operators. -/
def asInt : PyAny → Option Int
  | .int n => some n
  | .bool b => some (if b then 1 else 0)
  | _ => Option.none

def bitOp (f : Int → Int → Int) (a b : PyAny) : PyAny :=
  match asInt a, asInt b with | some x, some y => .int (f x y) | _, _ => .none
def shl (a b : PyAny) : PyAny := match asInt a, asInt b with | some x, some y => .int (pyShiftLeft x y) | _, _ => .none
def shr (a b : PyAny) : PyAny := match asInt a, asInt b with | some x, some y => .int (pyShiftRight x y) | _, _ => .none

/-- Numeric/string comparison, `none` when the operands are incomparable (as Python raises). -/
def cmp (a b : PyAny) : Option Ordering :=
  match a, b with
  | .str x, .str y => some (compare x y)
  | .list x, .list y => some (compare (x.map (·.toStr false)) (y.map (·.toStr false)))
  | _, _ => match asNum a, asNum b with
      | some x, some y => some (compare (toRat x) (toRat y))
      | _, _ => Option.none

def blt (a b : PyAny) : Bool := a.cmp b == some .lt
def ble (a b : PyAny) : Bool := a.cmp b == some .lt || a.cmp b == some .eq

/-- Python `==`: numeric across the tower (`5 == 5.0`), else structural (`5 == "5"` is `False`). -/
partial def beq (a b : PyAny) : Bool :=
  match asNum a, asNum b with
  | some x, some y => toRat x == toRat y
  | _, _ => match a, b with
      | .str x, .str y => x == y
      | .none, .none => true
      | .list x, .list y => x.length == y.length && (x.zip y).all fun (p, q) => beq p q
      | _, _ => false

end PyAny

instance : PyHAdd PyAny PyAny PyAny where hAdd := PyAny.add
instance : PyHSub PyAny PyAny PyAny where hSub := PyAny.sub
instance : PyHMul PyAny PyAny PyAny where hMul := PyAny.mul

/-- Mixed `PyAny op scalar` / `scalar op PyAny`: box the scalar and dispatch on the tags, so
arithmetic on an un-inferred (boxed) value against an `Int`/`ℚ` literal works (`x * 2` where `x` is a
`PyAny` element of an untyped param). Low priority so the exact `PyAny × PyAny` instances win. -/
instance (priority := low) {α} [PyToValue α] : PyHAdd PyAny α PyAny where hAdd a b := PyAny.add a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyHAdd α PyAny PyAny where hAdd a b := PyAny.add (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyHSub PyAny α PyAny where hSub a b := PyAny.sub a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyHSub α PyAny PyAny where hSub a b := PyAny.sub (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyHMul PyAny α PyAny where hMul a b := PyAny.mul a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyHMul α PyAny PyAny where hMul a b := PyAny.mul (PyToValue.toValue a) b

instance : PyHDiv PyAny PyAny PyAny where hDiv := PyAny.div
instance : PyModulo PyAny PyAny PyAny where hMod := PyAny.mod
instance : PyHPow PyAny PyAny PyAny where hPow := PyAny.pow
instance (priority := low) {α} [PyToValue α] : PyHDiv PyAny α PyAny where hDiv a b := PyAny.div a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyHDiv α PyAny PyAny where hDiv a b := PyAny.div (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyModulo PyAny α PyAny where hMod a b := PyAny.mod a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyModulo α PyAny PyAny where hMod a b := PyAny.mod (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyHPow PyAny α PyAny where hPow a b := PyAny.pow a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyHPow α PyAny PyAny where hPow a b := PyAny.pow (PyToValue.toValue a) b

/-- `==` on `PyAny` is numeric across the tower (`5 == 5.0`), replacing the structural derived `BEq`. -/
instance : BEq PyAny := ⟨PyAny.beq⟩

instance : LT PyAny := ⟨fun a b => PyAny.blt a b = true⟩
instance : LE PyAny := ⟨fun a b => PyAny.ble a b = true⟩
instance (a b : PyAny) : Decidable (a < b) := inferInstanceAs (Decidable (PyAny.blt a b = true))
instance (a b : PyAny) : Decidable (a ≤ b) := inferInstanceAs (Decidable (PyAny.ble a b = true))

instance : PyFloorDiv PyAny PyAny PyAny where floorDiv := PyAny.floordiv
instance : PyBitAnd PyAny PyAny PyAny where bitAnd := PyAny.bitOp (fun x y => pyBitAnd x y)
instance : PyBitOr PyAny PyAny PyAny where bitOr := PyAny.bitOp (fun x y => pyBitOr x y)
instance : PyBitXor PyAny PyAny PyAny where bitXor := PyAny.bitOp (fun x y => pyBitXor x y)
instance : PyShiftLeft PyAny PyAny PyAny where shiftLeft := PyAny.shl
instance : PyShiftRight PyAny PyAny PyAny where shiftRight := PyAny.shr
instance (priority := low) {α} [PyToValue α] : PyFloorDiv PyAny α PyAny where floorDiv a b := PyAny.floordiv a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyFloorDiv α PyAny PyAny where floorDiv a b := PyAny.floordiv (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyBitAnd PyAny α PyAny where bitAnd a b := PyAny.bitOp (fun x y => pyBitAnd x y) a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyBitAnd α PyAny PyAny where bitAnd a b := PyAny.bitOp (fun x y => pyBitAnd x y) (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyBitOr PyAny α PyAny where bitOr a b := PyAny.bitOp (fun x y => pyBitOr x y) a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyBitOr α PyAny PyAny where bitOr a b := PyAny.bitOp (fun x y => pyBitOr x y) (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyBitXor PyAny α PyAny where bitXor a b := PyAny.bitOp (fun x y => pyBitXor x y) a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyBitXor α PyAny PyAny where bitXor a b := PyAny.bitOp (fun x y => pyBitXor x y) (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyShiftLeft PyAny α PyAny where shiftLeft a b := PyAny.shl a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyShiftLeft α PyAny PyAny where shiftLeft a b := PyAny.shl (PyToValue.toValue a) b
instance (priority := low) {α} [PyToValue α] : PyShiftRight PyAny α PyAny where shiftRight a b := PyAny.shr a (PyToValue.toValue b)
instance (priority := low) {α} [PyToValue α] : PyShiftRight α PyAny PyAny where shiftRight a b := PyAny.shr (PyToValue.toValue a) b

/-- `float(x)` / the `/`-in-run-twin cast on a boxed value: read its numeric tag as a `Float`. -/
instance : PyFloatCast PyAny where
  pyFloat v := match PyAny.asNum v with
    | some (.inl n) => Float.ofInt n
    | some (.inr q) => q.toFloat
    | Option.none => 0.0

/-! ### Container protocols — delegate to the boxed value's own instance

A boxed slot that is indexed, iterated, or `len`-ed dispatches on the runtime tag and reuses the
concrete `List`/`String` instance (no reimplementation); the element is reboxed as `PyAny`. This
is why an un-inferred parameter can still be subscripted (`x[i]`, `x[i]=v`), looped, or measured. -/

instance : PyGetItem PyAny Int PyAny where
  getItem v i :=
    match v with
    | .list xs => pyListGetItem xs i
    | .str s => .str (pyStringGetItemStr s i)
    | _ => .none

instance : PySetItem PyAny Int PyAny where
  setItem v i x :=
    match v with
    | .list xs => .list (pySetItem xs i x)
    | _ => v

instance : PyLen PyAny where
  pyLen
    | .list xs => xs.length
    | .str s => s.length
    | _ => 0

instance : PyIterable PyAny PyAny where
  toPyList
    | .list xs => xs
    | .str s => s.toList.map (fun c => .str c.toString)
    | _ => []

instance : PyPrintable PyAny where pyStringify := PyAny.toStr false
/-- A `PyAny` is `None` exactly when it carries the `none` tag. -/
instance : PyIsNone PyAny where isNoneVal | .none => true | _ => false
instance : PyTruthy PyAny where
  truthy
    | .int n => n != 0
    | .bool b => b
    | .str s => !s.isEmpty
    | .float q => q != 0
    | .none => false
    | .list xs => !xs.isEmpty

end PastaLean
