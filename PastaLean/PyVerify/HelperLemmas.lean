import PastaLean.Imports
import PastaLean.PyAPI.Core
import PastaLean.PyAPI.Operators
import PastaLean.PyAPI.CommonProtocols.Length
import PastaLean.PyAPI.CommonProtocols.GetItem
import PastaLean.PyAPI.Lists
import PastaLean.PyAPI.Strings
import PastaLean.PyAPI.TasteIngr
import PastaLean.PyVerify.PyWhile

/-!
# Helper lemmas for contract verification

`pyRange n` (Python `range(n)`) is `[0, 1, …, n-1]` as `Int`. mvcgen verifies loops over native
`List.range` out of the box (it recovers "element = index", membership, length, …), but `pyRange`
hides that behind an `Int`-cast. The fix is **one reduction spec** — `pyRange_forIn` — that rewrites
a `pyRange` loop into the equivalent native `List.range` loop (with the cast pushed into the body).
Pass it to mvcgen (`mvcgen [fn, pyRange_forIn] …`) and *every* `pyRange` loop inherits `List.range`'s
full native support, for any invariant style. This is the extensible approach: one spec per Python
container reducing it to its Mathlib primitive, rather than ad-hoc per-invariant lemmas.
-/

namespace PastaLean

/-- The `List Nat → List Int` coercion is elementwise `Int.ofNat`. -/
theorem coe_list_eq (l : List Nat) : (↑l : List Int) = l.map Int.ofNat := by
  induction l with
  | nil => rfl
  | cons h t ih => simp_all [Int.ofNat_eq_natCast]

/-- `pyRange n` (default start 0, step 1) is `List.range n.toNat` cast to `Int`. -/
theorem pyRange_eq_ofNat (n : Int) : pyRange n = (List.range n.toNat).map Int.ofNat := by
  unfold pyRange
  simp_all [List.range_eq_range', show (Int.toNat 1) = 1 from rfl, add_sub_cancel_right]
  rw [← coe_list_eq]; simp only [List.pure_def, List.bind_eq_flatMap]

/-- **The reduction spec.** A `pyRange n` loop equals the native `List.range n.toNat` loop with the
`Int` cast pushed into the body. Pass to mvcgen so index-style invariants close as they do for
`List.range`. -/
@[taste_ingr] theorem pyRange_forIn {β : Type} {m : Type → Type} [Monad m] [LawfulMonad m]
    (n : Int) (init : β) (f : Int → β → m (ForInStep β)) :
    forIn (pyRange n) init f = forIn (List.range n.toNat) init (fun (k : Nat) => f (Int.ofNat k)) := by
  rw [pyRange_eq_ofNat, List.forIn_map]

/-- `pyRange stop start` (Python `range(start, stop)`, step 1) is `[start, …, stop-1]` as `Int`. -/
theorem pyRange_eq_start (stop start : Int) :
    pyRange stop start = (List.range (stop - start).toNat).map (fun k => start + Int.ofNat k) := by
  unfold pyRange
  simp only [List.range_eq_range', Int.ediv_one, add_sub_cancel_right]
  rw [coe_list_eq, List.map_map]; rfl

/-- Start-aware reduction: a `for i in range(start, stop)` loop becomes the native `List.range` loop
with the element `start + index` in the body, so mvcgen knows `i ≥ start`. -/
@[taste_ingr] theorem pyRange_forIn_start {β : Type} {m : Type → Type} [Monad m] [LawfulMonad m]
    (stop start : Int) (init : β) (f : Int → β → m (ForInStep β)) :
    forIn (pyRange stop start) init f
      = forIn (List.range (stop - start).toNat) init (fun (k : Nat) => f (start + Int.ofNat k)) := by
  rw [pyRange_eq_start, List.forIn_map]

/-! ### Membership reductions for quantified contracts
A contract `all`/`any` lowers to `∀`/`∃ x ∈ pyIter it`; these reduce that membership hypothesis to
plain index arithmetic. -/

/-- `pyIter` on a list is the list itself, so `∀ x ∈ pyIter l, …` is ordinary list membership. -/
@[simp, taste_ingr] theorem pyIter_list {α : Type} (l : List α) : pyIter l = l := rfl

/-- Membership in `range(n)`: the workhorse for a quantified contract over indices. -/
@[simp, taste_ingr] theorem pyRange_mem {n x : Int} : x ∈ pyRange n ↔ 0 ≤ x ∧ x < n := by
  rw [pyRange_eq_ofNat]
  simp only [List.mem_map, List.mem_range, Int.ofNat_eq_natCast]
  constructor
  · rintro ⟨k, hk, rfl⟩; omega
  · intro ⟨h0, hn⟩; exact ⟨x.toNat, by omega, by omega⟩

/-- Membership in `range(start, stop)`. -/
@[simp, taste_ingr] theorem pyRange_mem_start {stop start x : Int} :
    x ∈ pyRange stop start ↔ start ≤ x ∧ x < stop := by
  rw [pyRange_eq_start]
  simp only [List.mem_map, List.mem_range, Int.ofNat_eq_natCast]
  constructor
  · rintro ⟨k, hk, rfl⟩; omega
  · intro ⟨h0, hn⟩; exact ⟨(x - start).toNat, by omega, by omega⟩

/-- Python `x ** 2` lowers to `x ^ₚ (2 : Int)` (the `PyHPow Int Int Int` instance). `taste?`'s
closers (`positivity`/`nlinarith`) don't see through the `^ₚ` notation, so normalise it to the plain
`x ^ 2` monoid power — then `positivity` recognises the even power as nonnegative. Squares dominate
the contract goals (sum-of-squares, variance); higher powers can get their own reductions as needed. -/
@[taste_ingr] theorem pyHPow_two (a : Int) : a ^ₚ (2 : Int) = a ^ 2 := rfl

/-- Python `len` is a non-negative `Int` (a `Nat` count), which many postconditions/invariants rely
on (`0 ≤ len`, `i ≤ len`). One `@[taste_ingr]` lemma per concrete container. -/
@[taste_ingr] theorem pyLen_list_nonneg {α : Type} (xs : List α) : 0 ≤ pyLen xs := by
  simp [pyLen, PyLen.pyLen]
@[taste_ingr] theorem pyLen_nil {α : Type} : pyLen ([] : List α) = 0 := by
  simp [pyLen, PyLen.pyLen]

/-! String length is `.toList.length` (modern Lean's `String` is byte-backed but `String.toList_ofList`
recovers the char list, so it is NOT opaque). These let a loop building a `String` accumulator track its
length, the string analogue of `pyLen_pyAppend`. -/
@[taste_ingr] theorem pyLen_string_append (a b : String) : pyLen (a ++ b) = pyLen a + pyLen b := by
  simp [pyLen, PyLen.pyLen, String.length]
@[taste_ingr] theorem pyLen_string_hAdd_char (a : String) (c : Char) : pyLen (a +ₚ c) = pyLen a + 1 := by
  simp [pyLen, PyLen.pyLen, PyHAdd.hAdd, String.length]
/-- `swapcase` maps each character to one character, so it preserves length. -/
@[taste_ingr] theorem pyLen_pyStringSwapcase (s : String) : pyLen (pyStringSwapcase s) = pyLen s := by
  simp [pyLen, PyLen.pyLen, pyStringSwapcase, String.length, String.toList_ofList]

/-- Indexing a returned 2-tuple: `(a,b)[0] = a`, `(a,b)[1] = b`. Reduces the postcondition of any
function returning a pair (Python `return x, y`), which lowers to `result⦋0⦌`/`result⦋1⦌`. -/
@[taste_ingr] theorem pyGetItem_pair_zero {α : Type} [Inhabited α] (a b : α) :
    (a, b)⦋(0 : Int)⦌ = a := by
  simp [pyGetItem, PyGetItem.getItem, pyIter, pyListGetItem, PyIterable.toPyList]
@[taste_ingr] theorem pyGetItem_pair_one {α : Type} [Inhabited α] (a b : α) :
    (a, b)⦋(1 : Int)⦌ = b := by
  simp [pyGetItem, PyGetItem.getItem, pyIter, pyListGetItem, PyIterable.toPyList]
@[taste_ingr] theorem pyLen_string_nonneg (s : String) : 0 ≤ pyLen s := by
  simp [pyLen, PyLen.pyLen]

/-- Indexing a returned 2-element LIST literal (`return [x, y]`, e.g. `eat` returning `[a, b]`): the
list analogue of `pyGetItem_pair_*`. `[x,y][0] = x`, `[x,y][1] = y`. -/
@[taste_ingr] theorem pyGetItem_list_two_zero {α : Type} [Inhabited α] (a b : α) :
    [a, b]⦋(0 : Int)⦌ = a := by
  simp [pyGetItem, PyGetItem.getItem, pyListGetItem]
@[taste_ingr] theorem pyGetItem_list_two_one {α : Type} [Inhabited α] (a b : α) :
    [a, b]⦋(1 : Int)⦌ = b := by
  simp [pyGetItem, PyGetItem.getItem, pyListGetItem]

/-- Python TRUE division `a / b` on ints lowers to `a /ₚ b : ℚ` (the `PyHDiv Int Int Rat` instance,
`↑a / ↑b`). `ring`/`field_simp`/`push_cast` don't see through the `/ₚ` notation, so normalise it to
plain `ℚ` division — then the float/rational contract goals (`triangle_area`, variance, means) close. -/
@[taste_ingr] theorem pyDiv_int_int_rat (a b : Int) : (a /ₚ b : Rat) = (a : Rat) / (b : Rat) := rfl

/-- `append` (Python `list.append`) grows the length by one — the key rewrite for any loop whose
invariant tracks the length of an accumulator built with `pyAppend`. `@[taste_ingr]` so it fires in
the standard closer. -/
@[taste_ingr] theorem pyLen_pyListAppend {α : Type} (l : List α) (x : α) :
    pyLen (pyListAppend l x) = pyLen l + 1 := by
  simp [pyLen, PyLen.pyLen, pyListAppend]
@[taste_ingr] theorem pyLen_pyAppend {α : Type} (l : List α) (x : α) :
    pyLen (pyAppend l x) = pyLen l + 1 := pyLen_pyListAppend l x

/-- mvcgen's `for`-over-`List.range` cursor VCs carry a decomposition hypothesis
`List.range n = pref ++ cur :: suff` and then need the index bound `pref.length < n` (to justify
`i < len`). A `@[grind →]` forward rule so `grind` discharges those cursor-index VCs automatically. -/
@[grind →] theorem pyCursor_prefix_lt {n : Nat} {pref suff : List ℕ} {cur : ℕ}
    (h : List.range n = pref ++ cur :: suff) : pref.length < n := by
  have hl := congrArg List.length h
  simp [List.length_append, List.length_cons] at hl
  omega

/-- Generic list-iteration cursor bound: for `for x in xs`, the consumed prefix is a strict prefix,
so `pref.length < xs.length`. Covers char loops (`for ch in s`) and any `for x in <list>` whose
invariant tracks the number of elements seen. Plain (no concrete head to pattern on) — pass it to
`grind [pyCursor_listPrefix_lt]` when a char/list loop needs the bound. -/
theorem pyCursor_listPrefix_lt {α : Type} {xs pref suff : List α} {cur : α}
    (h : xs = pref ++ cur :: suff) : pref.length < xs.length := by
  grind only [= List.length_append, = List.length_cons]

/-- The cursor element `cur` of a `for i in range(n)` loop IS its index `pref.length`. mvcgen's VCs
speak of `cur` (the value pulled from the range) while the invariant speaks of the index; this bridges
them so index-dependent invariants (lengths, positions) discharge. `@[grind →]` like its sibling. -/
@[grind →] theorem pyCursor_prefix_eq {n : Nat} {pref suff : List ℕ} {cur : ℕ}
    (h : List.range n = pref ++ cur :: suff) : cur = pref.length := by
  have hlt : pref.length < n := pyCursor_prefix_lt h
  have hr : (List.range n)[pref.length]? = some pref.length := by
    simp [hlt]
  grind

-- `pyWhile`, its `while` rule (`pyWhile_correct`), and the `while → for` bridge (`pyWhile_count`) now
-- live in `PastaLean.PyVerify.PyWhile` (imported above), so all `pyWhile` material is in one file.

end PastaLean
