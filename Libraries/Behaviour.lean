import TypeInfer.PyType
import Libraries.Mutator

/-!
# Member behaviour: one self-describing record per Python callable

`pythonLibraryMap?` says *which Lean function* a Python member maps to. That is only half the story:
the transpiler also needs the **translation-relevant behaviour** a name→function map can't express —

* what type it *returns*, as a function of its argument types (so a binder can be typed by the join
  of its writes — see `docs/design-choices.md` §27), and
* whether it *teaches* one of its arguments a new element type by mutating it in place (`heappush(h,
  x)` makes `h` hold `x`), which drives the same widening chain.

Historically these lived as scattered `match name with …` arms inside `TypeInfer/Rules.lean` — so
adding a library, or a new builtin, meant editing the inference engine. `Behaviour` moves that
knowledge next to the mapping, where a library **self-describes**; each member is written as a named
return-*shape* combinator (`listOf 0`, `listOfTuples`, `push 0 1`), not a raw lambda.
-/

namespace Libraries
open TypeInfer

/-- How an in-place mutation refines the CONTAINER argument's element type (the inference side of a
mutation — a method's receiver counts as argument 0, so `xs.append(v)` and `heappush(h, v)` share
this). `container`/`element` are argument indices. -/
inductive Teaches where
  /-- Container gains `.list (type of the element arg)` — `append`, `insert`, `heappush`. -/
  | pushList   (container element : Nat)
  /-- Container gains `.set (type of the element arg)` — `add`. -/
  | pushSet    (container element : Nat)
  /-- Container gains `.list (ELEMENT type of the arg)` — `extend(xs)`, which splices `xs`'s elements. -/
  | extendList (container element : Nat)
  deriving Repr, BEq, Inhabited

/-- The behaviour of one Python callable beyond "it maps to Lean function F" — the single record both
inference AND the code generator read, so a library declares everything about a member in one place.
A method's RECEIVER is treated as argument 0, so methods and free functions share this record. Every
field has a "no information" default, so a member only declares what is non-trivial about it. -/
structure Behaviour where
  /-- Result type as a function of the argument types (receiver first, for a method). `.unknown` =
  "let inference infer it". [inference] -/
  returns  : List PyType → PyType := fun _ => .unknown
  /-- The element-type refinement this call performs by mutating an argument in place (feeds the
  widening chain), if any. [inference] -/
  teaches? : Option Teaches := none
  /-- How this call mutates its first argument IN PLACE at runtime — the code generator lowers the
  call through this (`xs.append(v)`, `heappush(h, v)`); the inference twin is `teaches?`. [codegen] -/
  mutator  : Option LibraryMutator := none
  /-- The unbounded-iterator shape of this call, if it never terminates (`count`, `cycle`), so a
  `for x in f(…)` header is desugared to a bounded `while`. [codegen] -/
  infiniteIter : Option InfiniteIter := none
  /-- The Lean function to route to when this member is called with a `key=` callback — the `*Key`
  shim variant that takes the callback (`bisect_left(a, x, key=f)` → `pyBisectLeftKey`). The code
  generator swaps the callee for this and passes `key` by name. [codegen] -/
  keyedVariant : Option Lean.Name := none

namespace Behaviour

/-- The `i`-th argument type, `.unknown` past the end. -/
private def arg (as : List PyType) (i : Nat) : PyType := (as[i]?).getD .unknown

/-! ### Return-shape combinators — a member declares its behaviour as a named shape, not a lambda. -/

/-- Always the fixed type `t` (`range` → `List Int`). -/
def const (t : PyType) : Behaviour := { returns := fun _ => t }
/-- The element type of argument `i` (`heappop(h)` returns `h`'s element). -/
def elementOf (i : Nat) : Behaviour := { returns := fun as => (arg as i).elemType }
/-- `List` of argument `i`'s element type (`sorted`, `list`, `deque`, `accumulate`). -/
def listOf (i : Nat) : Behaviour := { returns := fun as => .list (arg as i).elemType }
/-- `Set` of argument `i`'s element type (`set`, `frozenset`). -/
def setOf (i : Nat) : Behaviour := { returns := fun as => .set (arg as i).elemType }
/-- Argument `i`'s own type, unchanged (`dict(d)`, `OrderedDict(d)`, `abs(x)`). -/
def argType (i : Nat) : Behaviour := { returns := fun as => arg as i }
/-- `dict[element of arg i, int]` — a counting map (`Counter(xs)`). -/
def counterOf (i : Nat) : Behaviour := { returns := fun as => .dict (arg as i).elemType .int }
/-- `List` of tuples pairing every argument's element type (`zip`, `product`). -/
def listOfTuples : Behaviour := { returns := fun as => .list (.tuple (as.map (·.elemType))) }
/-- `List` of the arguments' common (joined) element type (`chain`). -/
def listOfJoined : Behaviour := { returns := fun as => .list (PyType.joinAll (as.map (·.elemType))) }
/-- `List (int, element of arg 0)` (`enumerate(xs)`). -/
def enumerated : Behaviour := { returns := fun as => .list (.tuple [.int, (arg as 0).elemType]) }
/-- `List (elem, elem)` of consecutive pairs (`pairwise(xs)`). -/
def adjacentPairs : Behaviour := { returns := fun as => let e := (arg as 0).elemType; .list (.tuple [e, e]) }
/-- One container argument → its element type; several arguments → their join (`min`, `max`). -/
def elementOrJoin : Behaviour := { returns := fun as => match as with
                                    | [x] => x.containerElemOrSelf | _ => PyType.joinAll as }
/-- One container argument → its element type; several arguments → the first (`sum`). -/
def elementOrFirst : Behaviour := { returns := fun as => match as with
                                    | [x] => x.containerElemOrSelf | _ => arg as 0 }
/-- `sum(xs)` / `sum(xs, start)`: the numeric element type, but `bool` counts as `int` (Python's
`sum([True, False, True]) = 2`), joined with the optional start value (arg 1). -/
def sumReturn : Behaviour := { returns := fun as =>
  let e := (arg as 0).containerElemOrSelf
  let e := if e == .bool then .int else e
  match as[1]? with | some s => e.join s | none => e }

/-! Dict-method returns — the receiver (a `dict[k, v]`) is argument 0. -/

/-- The receiver dict's keys as a list (`d.keys()`). -/
def dictKeys   : Behaviour := { returns := fun as => .list (match arg as 0 with | .dict k _ => k | _ => .unknown) }
/-- The receiver dict's values as a list (`d.values()`). -/
def dictValues : Behaviour := { returns := fun as => .list (match arg as 0 with | .dict _ v => v | _ => .unknown) }
/-- The receiver dict's `(key, value)` pairs as a list (`d.items()`). -/
def dictItems  : Behaviour := { returns := fun as => .list (match arg as 0 with | .dict k v => .tuple [k, v] | _ => .unknown) }

/-- The receiver's value type: a dict's value, else the container's element (`d[k]`-style). -/
private def valueOf (t : PyType) : PyType := match t with | .dict _ v => v | _ => t.elemType
/-- `d.get(k)` → `Optional[V]`; `d.get(k, default)` → `V` joined with the default's type (arg 2, after
the receiver). -/
def getShape : Behaviour := { returns := fun as =>
  let v := valueOf (arg as 0)
  match as[2]? with | some d => v.join d | none => .opt v }
/-- `d.pop(k)` / `xs.pop()` / `q.popleft()` / `d.setdefault(k)` → the receiver's value/element, joined
with an optional default (arg 2). -/
def popShape : Behaviour := { returns := fun as => (valueOf (arg as 0)).join ((as[2]?).getD .unknown) }

/-! Mutation shapes — for a method, `container` is the receiver (argument 0). -/

/-- `container` gains `.list (element's type)` — `xs.append(v)`, `xs.insert(i, v)`, `heappush(h, v)`. -/
def push (container element : Nat) : Behaviour := { teaches? := some (.pushList container element) }
/-- `container` gains `.set (element's type)` — `s.add(v)`. -/
def addTo (container element : Nat) : Behaviour := { teaches? := some (.pushSet container element) }
/-- `container` gains `.list (element ARG's element type)` — `xs.extend(ys)`. -/
def extendWith (container element : Nat) : Behaviour := { teaches? := some (.extendList container element) }

end Behaviour

/-- Behaviour of a Python **builtin** whose result depends on its arguments (`zip`, `min`, `range`).
Builtins with a fixed constant result stay in `constReturnBuiltins`; each *library's* members are
declared in that library's own `Mapping.lean` and aggregated by `Registry.bareBehaviour?`. -/
def builtinBehaviour? (name : String) : Option Behaviour :=
  open Behaviour in
  match name with
  | "range"                        => some (const (.list .int))
  | "list" | "sorted" | "reversed" => some (listOf 0)
  | "set" | "frozenset"            => some (setOf 0)
  | "tuple"                        => some (listOf 0)
  | "dict" | "abs"                 => some (argType 0)
  | "zip"                          => some listOfTuples
  | "enumerate"                    => some enumerated
  | "min" | "max"                  => some elementOrJoin
  | "sum"                          => some sumReturn
  -- `map(f, xs)` is a list (of `f`'s results — element type left open); knowing it is a LIST is what
  -- lets `a, b = map(int, s.split())` unpack by index instead of as a `Prod`.
  | "map"                          => some (const (.list .unknown))
  | _                              => none

/-- Behaviour of a builtin-type **method** `recv.m(args)`, with the RECEIVER as argument 0 — so
`d.items()` reads the receiver dict, and `xs.append(v)` teaches the receiver. Covers the constant str
returns (`s.split()` → `list str`), the receiver-dependent shapes (`keys`/`get`/`pop`), and the
mutations (`append`/`add`/`extend`). -/
def methodBehaviour? (method : String) : Option Behaviour :=
  open Behaviour in
  -- str/list methods with a constant result type
  if ["split", "rsplit", "splitlines"].contains method then some (const (.list .str))
  else if ["join", "strip", "lstrip", "rstrip", "lower", "upper", "replace", "format", "title",
           "swapcase", "casefold", "center", "removeprefix", "removesuffix",
           "rjust", "ljust"].contains method then some (const .str)
  else if ["count", "find", "rfind", "index"].contains method then some (const .int)
  else if ["startswith", "endswith", "isdigit", "isalpha"].contains method then some (const .bool)
  else match method with
  -- receiver-dependent returns
  | "keys"              => some dictKeys
  | "values"            => some dictValues
  | "items"             => some dictItems
  | "get"               => some getShape
  | "pop" | "popleft" | "popright" | "setdefault" => some popShape
  | "copy"              => some (argType 0)      -- returns the receiver's own type
  -- in-place mutations (receiver = arg 0)
  | "append"            => some (push 0 1)
  | "insert"            => some (push 0 2)        -- `xs.insert(i, v)`: the value is the 2nd real arg
  | "add"               => some (addTo 0 1)
  | "extend"            => some (extendWith 0 1)
  | _                   => none

/-- The type a **type-exclusive** builtin method pins its RECEIVER to (the reverse of a return: `def
f(p): return p.split()` types `p : str`). Only methods belonging to exactly ONE builtin type are
listed — Python semantics, exhaustively; shared methods are omitted on purpose (`pop` is list AND
dict; `remove` list AND set; `index`/`count` list/str/tuple; `update` dict AND set) so a receiver is
never mis-typed. Consulted by parameter inference. -/
def builtinMethodReceiver? (attr : String) : TypeInfer.PyType :=
  -- str-only: no list/dict/set/tuple has these.
  if ["split", "rsplit", "splitlines", "upper", "lower", "title", "capitalize", "casefold",
      "swapcase", "strip", "lstrip", "rstrip", "replace", "startswith", "endswith", "find", "rfind",
      "join", "format", "format_map", "ljust", "rjust", "center", "zfill", "encode", "expandtabs",
      "partition", "rpartition", "removeprefix", "removesuffix", "translate", "maketrans",
      "isdigit", "isalpha", "isalnum", "isspace", "isupper", "islower", "istitle", "isnumeric",
      "isdecimal", "isidentifier", "isprintable", "isascii"].contains attr then .str
  -- list-only (`pop`/`remove`/`index`/`count` are shared → excluded).
  else if ["append", "extend", "insert", "sort", "reverse"].contains attr then .list .unknown
  -- dict-only (`update`/`pop` shared).
  else if ["keys", "values", "items", "get", "setdefault", "popitem", "fromkeys"].contains attr
    then .dict .unknown .unknown
  -- set-only (`remove`/`update`/`union`&co are shared or on frozenset).
  else if ["add", "discard", "issubset", "issuperset", "isdisjoint", "symmetric_difference",
           "symmetric_difference_update", "difference_update", "intersection_update"].contains attr
    then .set .unknown
  else .unknown

end Libraries
