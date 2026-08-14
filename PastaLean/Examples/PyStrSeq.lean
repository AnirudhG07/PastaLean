import PastaLean

/-!
# `PyStrSeq` — a *bounded* dynamic type for the `str`-vs-`list[str]` ambiguity

When a parameter is used only through operations that are **uniform** across a Python `str` and a
`list[str]` — indexing, iteration, `len`, truthiness — its type is genuinely undecidable without a
hint (see `PastaBench/humaneval/README.md`). Today such a parameter is boxed to `PyAny` (⊤), which
loses too much: `word[i] : PyAny`, so a concrete `str`-typed use like `is_vowel(word[i])` no longer
elaborates.

`PyStrSeq` carries **more information** than `PyAny`: it commits to "a sequence whose elements are
`String`", keeping a normalized `List String` carrier plus a provenance tag. That single fact is
enough to make every ambiguity-creating operation return a **concrete** type:

| op            | on `PyAny`   | on `PyStrSeq` |
|---------------|--------------|---------------|
| `word[i]`     | `PyAny`      | **`String`**  |
| `for c in word` | `PyAny`    | **`String`**  |
| `len word`    | `Int`        | `Int`         |

So `is_vowel(word[i])` — the thing that fails under `PyAny` — elaborates, and proofs run on the
concrete `List String` carrier with no dynamic case-split. The `fromStr` tag keeps the value faithful
to its origin (a `str` round-trips to a `str`), so it is *sound*, not a guess: at run time the caller's
value fixes the tag; a proof that quantifies over `PyStrSeq` covers **both** a string and a list.
-/

namespace PastaLean.Examples

/-- A value known to be a Python `str` OR a `list[str]`: its element sequence (a `str` is its list of
one-character strings) plus a tag recording which it came from. -/
structure PyStrSeq where
  elems   : List String
  fromStr : Bool
  deriving Repr

namespace PyStrSeq

/-- A Python `str` becomes the list of its characters as 1-char strings (`"ab" → ["a","b"]`). -/
instance : Coe String PyStrSeq := ⟨fun s => ⟨s.toList.map Char.toString, true⟩⟩
/-- A `list[str]` is its elements verbatim. -/
instance : Coe (List String) PyStrSeq := ⟨fun l => ⟨l, false⟩⟩

/-- Every ambiguity-creating op lands on the concrete carrier `elems : List String`. -/
instance : PastaLean.PyLen PyStrSeq := ⟨fun w => w.elems.length⟩
instance : PastaLean.PyGetItem PyStrSeq Int String := ⟨fun w i => w.elems[i.toNat]!⟩
instance : PastaLean.PyIterable PyStrSeq String := ⟨fun w => w.elems⟩
instance : PastaLean.PyContains PyStrSeq String := ⟨fun w x => w.elems.contains x⟩
instance : PastaLean.PyTruthy PyStrSeq := ⟨fun w => !w.elems.isEmpty⟩

end PyStrSeq

/-! ### A `get_closest_vowel`-shaped demo -/

def isVowel (ch : String) : Bool := ["a","e","i","o","u","A","E","I","O","U"].contains ch

open PastaLean in
/-- First vowel in the sequence, or `""`. Note `pyIter word : List String` and the element `ch` is a
concrete `String`, so `isVowel ch` typechecks — exactly what fails when `word : PyAny`. -/
def firstVowel (word : PyStrSeq) : String :=
  ((PastaLean.pyIter word).find? (fun ch => isVowel ch)).getD ""

-- Runs for a `str`-origin value and a `list[str]`-origin value — the tag comes from the caller's data.
#eval firstVowel (↑"yogurt" : PyStrSeq)          -- "o"
#eval firstVowel (↑["b", "c", "a", "e"] : PyStrSeq)  -- "a"

open PastaLean in
/-- The postcondition — "the result is empty or a vowel" — holds for **both** a `str` and a `list[str]`
in one proof, because the carrier is a concrete `List String`. No `PyAny` dispatch, no per-tag split. -/
theorem firstVowel_spec (word : PyStrSeq) :
    firstVowel word = "" ∨ isVowel (firstVowel word) = true := by
  unfold firstVowel
  cases h : ((PastaLean.pyIter word).find? (fun ch => isVowel ch)) with
  | none => left; rfl
  | some ch => right; simp only [Option.getD]; exact List.find?_some h

end PastaLean.Examples
