import PastaLean.PyAPI.Core
import PastaLean.PyAPI.Lists
import PastaLean.PyAPI.CommonProtocols.GetItem
import PastaLean.PyAPI.CommonProtocols.SetItem
import PastaLean.PyAPI.CommonProtocols.Length
import PastaLean.PyAPI.CommonProtocols.Membership
import PastaLean.PyAPI.CommonProtocols.Truthy
import PastaLean.PyAPI.CommonProtocols.Bool
import PastaLean.PyAPI.PyPrint

/-! # Array-backed sequences for the runnable (`'rn`) twin

Python `list` is a dynamic array — O(1) amortized append, O(1) index — but a `List α`-backed
`xs := xs ++ [v]` append is O(n) and `xs[i]` is O(i), so an append/index loop is O(n²) (validated:
`List` append+index at n=30000 ran ~134× slower than `Array`). The **provable** twin keeps `List α`
(Mathlib lemmas); the **runnable** (`'rn`) twin uses `Array α`, whose `push`/`set!`/`get!` are O(1)
when the array is uniquely owned — which the codegen's threaded mutation (`xs := pyArrayAppend xs v`,
reassigning the same binder) guarantees, so Lean's Perceus reference counting mutates in place.

Every op mirrors its `pyList*` / `List` protocol counterpart's Python semantics (negative indices,
`IndexError` on out-of-range) so the two twins agree on results. `List` remains the fallback: the
generated code is identical except for the binder type, so a value the codegen can't prove safe to
back with `Array` is simply stamped `List α` and uses the `List` instances instead. -/

namespace PastaLean

/-- O(1) indexed read with Python negative-index semantics (mirrors `pyListGetItem`). -/
def pyArrayGetItem {α : Type} [Inhabited α] (xs : Array α) (idx : Int) : α :=
  let len := xs.size
  if len == 0 then panic! "IndexError: list index out of range"
  else
    let lenInt : Int := len
    let trueIdx := if idx < 0 then lenInt + idx else idx
    if trueIdx < 0 || trueIdx >= lenInt then panic! "IndexError: list index out of range"
    else xs[trueIdx.toNat]!

/-- O(1) indexed write with Python negative-index semantics (mirrors the `PySetItem (List β)` body).
`Array.set!` mutates in place when `xs` is uniquely owned. -/
def pyArraySetItem {α : Type} (xs : Array α) (idx : Int) (v : α) : Array α :=
  let len := xs.size
  let lenInt : Int := len
  let trueIdx := if idx < 0 then lenInt + idx else idx
  if trueIdx < 0 || trueIdx >= lenInt then
    panic! "IndexError: list assignment index out of range"
  else xs.set! trueIdx.toNat v

/-- O(1) amortized append — in place when uniquely owned (`list.append`). -/
def pyArrayAppend {α : Type} (xs : Array α) (v : α) : Array α := xs.push v

/-- `[x] * n` sequence repeat: the (usually one-element) array `xs` concatenated `n` times. -/
def pyArrayRepeat {α : Type} (xs : Array α) (n : Int) : Array α :=
  if n ≤ 0 then #[] else Id.run do
    let mut out := Array.emptyWithCapacity (n.toNat * xs.size)
    for _ in [0:n.toNat] do
      out := out ++ xs
    return out

/-- `list.extend` / `a + b` concatenation. -/
def pyArrayExtend {α : Type} (xs ys : Array α) : Array α := xs ++ ys

instance {β : Type} [Inhabited β] : PyGetItem (Array β) Int β where
  getItem xs i := pyArrayGetItem xs i

instance {β : Type} : PySetItem (Array β) Int β where
  setItem xs i v := pyArraySetItem xs i v

/-- O(1) in-place nested update — `a[i] = f(a[i])`. `Array.modify` takes the element out (dropping its
refcount to 1), applies `f`, and puts it back, so `a[i][j] = v` is O(1), not an O(n) row copy. -/
instance {β : Type} [Inhabited β] : PyModifyItem (Array β) Int β where
  modifyItem xs idx g :=
    let sz : Int := xs.size
    let t := if idx < 0 then sz + idx else idx
    if t < 0 || t >= sz then panic! "IndexError: list assignment index out of range"
    else xs.modify t.toNat g

instance {α : Type} : PyLen (Array α) where
  pyLen xs := xs.size

/-- Slicing (`a[lo:hi:step]`) via `List` — inherently O(n), so an `Array`-backed sieve var may still
be sliced without dropping its O(1) index/write. -/
instance {β : Type} : PySlice (Array β) where
  slice xs lo hi step := (pyListSliceStep xs.toList lo hi step).toArray

instance {α : Type} [BEq α] : PyContains (Array α) α where
  contains xs x := xs.contains x

instance {α : Type} : PyTruthy (Array α) where
  truthy xs := !xs.isEmpty

instance {α : Type} : PyBool (Array α) where
  pyBool xs := xs.size != 0

instance {α : Type} [PyPrintable α] : PyPrintable (Array α) where
  pyStringify xs := "[" ++ String.intercalate ", " (xs.toList.map pyStringify) ++ "]"

end PastaLean
