import PastaLean.Imports
import PastaLean.PyAPI.CommonProtocols.Iterable
import PastaLean.PyAPI.CommonProtocols.Length
import PastaLean.PyAPI.CommonProtocols.Membership
import PastaLean.PyAPI.CommonProtocols.Truthy
import PastaLean.PyAPI.CommonProtocols.Pop
import PastaLean.PyAPI.CommonProtocols.Sorting
import PastaLean.PyAPI.PyPrint
import PastaLean.PyAPI.Operators

namespace PastaLean

/-!
Python-style sets.

A set is an **insertion-ordered** list (`toList`, the Python-visible iteration order — matching the
previous list-backed representation exactly) paired with a `Std.HashSet` index (`mem`) used only for
`in`/`add`, so membership and insertion are O(1) instead of O(n). Every order-observing protocol
(iteration, `len`, printing, JSON, comprehension) delegates to `toList`, so switching to this
representation changes only the *speed* of membership, never the observable order or semantics.

Elements need `BEq` and `Hashable` (Python set elements are hashable anyway). Like the other container
runtimes these are immutable values: `s.add(x)` rebuilds the set and codegen reassigns the variable.
-/

structure PySet (α : Type) [BEq α] [Hashable α] where
  /-- Insertion order, backed by an `Array` so `add` is O(1) amortized (a `List` end-append is O(n),
  which reintroduces O(n²) over a membership loop). Observations convert to a list once via `toList`. -/
  order : Array α
  mem : Std.HashSet α

variable {α : Type} [BEq α] [Hashable α]

def PySet.empty : PySet α := ⟨#[], ∅⟩

/-- The Python-visible iteration order (insertion order). O(n), evaluated once per observation. -/
def PySet.toList (s : PySet α) : List α := s.order.toList

instance : Inhabited (PySet α) := ⟨PySet.empty⟩
instance : EmptyCollection (PySet α) := ⟨PySet.empty⟩

/-- Insert `x` if not already present, keeping insertion order (O(1) amortized). -/
def PySet.insert (s : PySet α) (x : α) : PySet α :=
  if s.mem.contains x then s else ⟨s.order.push x, s.mem.insert x⟩

def PySet.contains (s : PySet α) (x : α) : Bool := s.mem.contains x

/-- Build a set from a list, dropping duplicates (used for `{a, b, c}` literals and `set(xs)`). -/
def pySetFromList (xs : List α) : PySet α :=
  xs.foldl (fun acc x => acc.insert x) PySet.empty

/-- Python `set(iterable)` for any iterable, normalized through `pyIter`. -/
def pySet {β : Type} [PyIterable β α] (xs : β) : PySet α :=
  pySetFromList (pyIter xs)

/-- Python `s.add(x)`: insert `x` if not already present. -/
def pySetAdd (s : PySet α) (x : α) : PySet α := s.insert x

/-- Python `s.discard(x)`: remove `x` if present (no error if absent). -/
def pySetDiscard (s : PySet α) (x : α) : PySet α :=
  ⟨s.order.filter (fun y => y != x), s.mem.erase x⟩

/-- Python `s.remove(x)`: like `discard` here (we do not raise `KeyError` on absence). -/
def pySetRemove (s : PySet α) (x : α) : PySet α := pySetDiscard s x

/-! ### Binary set operations (`|`, `&`, `-`, `^`), keeping insertion order of the result. -/

/-- Python set union `a | b`: elements in either set (order: `a` then new elements of `b`). -/
def pySetUnion (a b : PySet α) : PySet α :=
  b.toList.foldl (fun acc x => acc.insert x) a

/-- Python set intersection `a & b`: elements in both sets. -/
def pySetIntersection (a b : PySet α) : PySet α :=
  ⟨a.order.filter (fun x => b.contains x), a.mem.filter (fun x => b.contains x)⟩

/-- Python set difference `a - b`: elements of `a` not in `b`. -/
def pySetDifference (a b : PySet α) : PySet α :=
  ⟨a.order.filter (fun x => !b.contains x), a.mem.filter (fun x => !b.contains x)⟩

/-- Python symmetric difference `a ^ b`: elements in exactly one of the two sets. -/
def pySetSymmetricDifference (a b : PySet α) : PySet α :=
  pySetUnion (pySetDifference a b) (pySetDifference b a)

/-- Python set equality `a == b`: same elements, order-independent. -/
def pySetEq (a b : PySet α) : Bool :=
  a.toList.length == b.toList.length && a.toList.all (fun x => b.contains x)

/-- Python subset `a <= b`: every element of `a` is in `b`. -/
def pySetSubset (a b : PySet α) : Bool := a.toList.all (fun x => b.contains x)

/-- Python proper subset `a < b`. -/
def pySetProperSubset (a b : PySet α) : Bool :=
  pySetSubset a b && !pySetEq a b

/-- Python `a.issuperset(b)`: every element of `b` is in `a`. -/
def pySetSuperset (a b : PySet α) : Bool := pySetSubset b a

/-- Python `a.isdisjoint(b)`: `a` and `b` share no element. -/
def pySetIsDisjoint (a b : PySet α) : Bool := a.toList.all (fun x => !b.contains x)

/-! ### Protocol instances — order-observing ones delegate to `toList`; only membership uses `mem`. -/

instance : PyContains (PySet α) α where contains s x := s.mem.contains x
instance : PyLen (PySet α) where pyLen s := s.toList.length
instance : PyIterable (PySet α) α where toPyList s := s.toList
instance : PyTruthy (PySet α) where truthy s := !s.toList.isEmpty
instance : BEq (PySet α) where beq a b := pySetEq a b

instance [PyPrintable α] : PyPrintable (PySet α) where
  pyStringify s :=
    if s.toList.isEmpty then "set()"
    else "{" ++ String.intercalate ", " (s.toList.map PyPrintable.pyStringify) ++ "}"

instance [Lean.ToJson α] : Lean.ToJson (PySet α) where
  toJson s := Lean.toJson s.toList

instance [Lean.FromJson α] : Lean.FromJson (PySet α) where
  fromJson? j := do
    let xs ← Lean.fromJson? (α := List α) j
    pure (pySetFromList xs)

instance {m : Type → Type} [Monad m] : ForIn m (PySet α) α where
  forIn s init f := forIn s.toList init f

/-! The binary set operators reuse the surface names of the integer bitwise operators and `-`. -/
/-- `set.pop()` removes an arbitrary element: reuse the list logic on `toList`, rebuild the set. -/
instance : PyPopRestSeq (PySet α) where
  popRestAt s idx := pySetFromList (PyPopRestSeq.popRestAt s.toList idx)
instance [Inhabited α] : PyPopValSeq (PySet α) α where
  popValAt s idx := PyPopValSeq.popValAt s.toList idx

/-- `sorted(s)` on a set returns a sorted list (reuse the list sort on `toList`). -/
instance [Ord α] : PySort (PySet α) α where pySort s := pySort s.toList

instance : PyBitAnd (PySet α) (PySet α) (PySet α) where bitAnd := pySetIntersection
instance : PyBitOr (PySet α) (PySet α) (PySet α) where bitOr := pySetUnion
instance : PyBitXor (PySet α) (PySet α) (PySet α) where bitXor := pySetSymmetricDifference
instance : PyHSub (PySet α) (PySet α) (PySet α) where hSub := pySetDifference

end PastaLean
