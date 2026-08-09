import PastaLean

/-!
# Bounded dynamic typing via a **type-valued function** (no union, no wrapper)

For a parameter whose type is undecidable between a small shortlist of candidates that share the
operations used on it (the `str`-vs-`list[str]` case: both are indexable/iterable "sequences of
`String`"), we do NOT box to `PyAny` (⊤) and we do NOT wrap it in a union. Instead — exactly like
`Examples/LengthMultiReturn.lean` — we index a **type-valued function** by a discriminator tag:

    candType .str  = String        -- the value is a *real* String
    candType .list = List String   -- the value is a *real* List String

A value of `candType t` is the native type, zero-cost, faithful. One instance per shared protocol,
defined by matching the tag, makes every uniform op land on a **concrete** result (`word[i] : String`),
which is what `PyAny` cannot give. The caller's runtime value fixes `t`; a proof `∀ t, …` covers every
shortlisted candidate. This is the honest "it works for a string and for a list of strings."

**Threshold.** This pays off only while the candidates are *close* (their shared interface is rich).
Past a small shortlist the common operations degrade to the generic container protocols that `PyAny`
already models, while the proof obligations multiply per tag. Recommended cap: **2** (optionally 3);
`≥ 3` distinct candidates ⇒ fall back to `PyAny`. See the note at the bottom.
-/

namespace PastaLean.Examples

/-- The shortlist of candidate readings for one ambiguous parameter (kept ≤ the threshold). -/
inductive Cand where | str | list
  deriving DecidableEq

/-- The type-valued function: each tag maps to a *real* Lean type the value literally has. -/
def candType : Cand → Type
  | .str  => String
  | .list => List String

/-- Every ambiguity-creating op has one instance, matching the tag; each lands on concrete `String`. -/
instance (t : Cand) : PastaLean.PyLen (candType t) where
  pyLen := match t with
    | .str  => fun (w : String)      => (w.length : Int)
    | .list => fun (w : List String) => (w.length : Int)

instance (t : Cand) : PastaLean.PyGetItem (candType t) Int String where
  getItem := match t with
    | .str  => fun (w : String)      i => (w.toList[i.toNat]!).toString
    | .list => fun (w : List String) i => w[i.toNat]!

instance (t : Cand) : PastaLean.PyIterable (candType t) String where
  toPyList := match t with
    | .str  => fun (w : String)      => w.toList.map Char.toString
    | .list => fun (w : List String) => w

instance (t : Cand) : PastaLean.PyTruthy (candType t) where
  truthy := match t with
    | .str  => fun (w : String)      => !w.isEmpty
    | .list => fun (w : List String) => !w.isEmpty

/-! ### A `get_closest_vowel`-shaped demo -/

def isVowel (ch : String) : Bool := ["a","e","i","o","u","A","E","I","O","U"].contains ch

open PastaLean in
/-- Polymorphic over the tag `t`. `pyIter word : List String`, so the element `ch` is a concrete
`String` and `isVowel ch` typechecks — the exact use that fails when `word : PyAny`. -/
def firstVowel (t : Cand) (word : candType t) : String :=
  ((PastaLean.pyIter word).find? (fun ch => isVowel ch)).getD ""

-- Runs for a *real* String (tag `.str`) and a *real* List String (tag `.list`).
#eval firstVowel .str  "yogurt"            -- "o"
#eval firstVowel .list ["b", "c", "a", "e"]  -- "a"

open PastaLean in
/-- The postcondition holds for **every** shortlisted candidate — one proof, quantified over the tag.
It doesn't even need to split on `t` here, because `pyIter` already unifies the branches. -/
theorem firstVowel_spec (t : Cand) (word : candType t) :
    firstVowel t word = "" ∨ isVowel (firstVowel t word) = true := by
  unfold firstVowel
  cases h : ((PastaLean.pyIter word).find? (fun ch => isVowel ch)) with
  | none => left; rfl
  | some ch => right; simp only [Option.getD]; exact List.find?_some h

/-! ### Where the type-function is ESSENTIAL: the type decided at RUNTIME

In Python the type is genuinely runtime data — `count_upper(x)` gets a `str` or a `list[str]` depending
on what the caller computed. The type-valued function models this *directly*: the tag flows from
runtime input, and `candType tag` is a value whose Lean type DEPENDS on that runtime tag. Bounded
polymorphism cannot express this (it needs the type fixed at the call site); here the dependent type is
exactly right. -/

/-- Decide the reading from the runtime value itself (stands in for however Python produced it). -/
def classify (raw : String) : Cand := if raw.contains ',' then .list else .str

/-- Build a value of the RUNTIME-chosen type `candType (classify raw)`. The result type depends on
runtime data; the `match` refines it per branch. -/
def parse (raw : String) : candType (classify raw) :=
  match classify raw with
  | .str  => raw
  | .list => raw.splitOn ","

/-- Full runtime flow: tag computed from data → value whose TYPE depends on it → processed uniformly.
One code path serves both a string and a list, chosen at runtime — exactly Python's dispatch. -/
def firstVowelOf (raw : String) : String := firstVowel (classify raw) (parse raw)

#eval firstVowelOf "yogurt"    -- "o"   (runtime tag resolves to .str)
#eval firstVowelOf "b,c,a,e"   -- "a"   (runtime tag resolves to .list)

/-- And the correctness proof still covers the runtime case, via the generic `firstVowel_spec`. -/
theorem firstVowelOf_spec (raw : String) :
    firstVowelOf raw = "" ∨ isVowel (firstVowelOf raw) = true :=
  firstVowel_spec (classify raw) (parse raw)

end PastaLean.Examples
