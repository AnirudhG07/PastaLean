import PastaLean

/-!
# `PyDyn elem` — a `PyAny` that dispatches at RUNTIME but reads elements at a CONCRETE type

This is the synthesis you asked for. `PyAny` already carries a runtime tag and dispatches on it
(`PyGetItem PyAny Int PyAny` does `.str s => …`, `.list xs => …`), so it handles a type decided at
runtime. Its only flaw is that every op *returns* `PyAny`, so `is_vowel(word[i])` (a concrete
`String`-typed use) breaks.

`PyDyn elem` reuses that exact engine and just **unboxes each result to `elem`**. So `word[i] : String`
(concrete, provable) while the str-vs-list decision still happens at runtime inside `PyAny`. Almost no
new code: each instance delegates to `PyAny`'s instance and applies `Unbox.unbox`. The shortlist that
produced the value guarantees the tag, so the default arm of `unbox` is unreachable at run time and only
keeps the function total.
-/

namespace PastaLean.Examples
open PastaLean

/-- Read a boxed `PyAny` back at a concrete element type. One tiny instance per element type. -/
class Unbox (α : Type) where unbox : PyAny → α
instance : Unbox String := ⟨fun x => match x with | .str s => s | _ => ""⟩
instance : Unbox Int    := ⟨fun x => match x with | .int n => n | .bool b => if b then 1 else 0 | _ => 0⟩
instance : Unbox PyAny  := ⟨id⟩   -- a genuinely dynamic element stays `PyAny` — no unbox

/-- A `PyAny` viewed as a sequence whose elements read as `elem`. A newtype (not a bare alias) so its
instances don't collide with `PyAny`'s own. -/
structure PyDyn (elem : Type) where val : PyAny

namespace PyDyn

/-- Box a real `str`/`list[str]` into the dynamic view (what the caller/harness does at runtime). -/
instance : Coe String (PyDyn String)       := ⟨fun s => ⟨.str s⟩⟩
instance : Coe (List String) (PyDyn String) := ⟨fun l => ⟨.list (l.map .str)⟩⟩
instance : Coe (List Int) (PyDyn Int)        := ⟨fun l => ⟨.list (l.map .int)⟩⟩

/-- The four ops: DELEGATE to `PyAny`'s runtime dispatch, then `unbox` to the concrete `elem`. -/
instance {elem} [Unbox elem] : PyGetItem (PyDyn elem) Int elem where
  getItem x i := Unbox.unbox (pyGetItem x.val i)
instance {elem} [Unbox elem] : PyIterable (PyDyn elem) elem where
  toPyList x := (pyIter x.val).map Unbox.unbox
instance {elem} : PyLen (PyDyn elem) where pyLen x := pyLen x.val
instance {elem} : PyTruthy (PyDyn elem) where truthy x := pyTruthy x.val

end PyDyn

/-! ### Demo: the same `PyDyn String` value is a str OR a list, decided at runtime -/

def isVowel (ch : String) : Bool := ["a","e","i","o","u","A","E","I","O","U"].contains ch

open PastaLean in
/-- `pyIter word : List String` (unboxed), so `ch : String` and `isVowel ch` typechecks — the use that
fails on raw `PyAny`. -/
def firstVowel (word : PyDyn String) : String :=
  ((PastaLean.pyIter word).find? (fun ch => isVowel ch)).getD ""

-- Boxed from a real str / list[str] via `Coe`:
#eval firstVowel (↑"yogurt")            -- "o"
#eval firstVowel (↑["b", "c", "a", "e"]) -- "a"

open PastaLean in
/-- THE runtime case: `x : PyAny` whose tag is only known at run time (str? list?) — viewed as a
`PyDyn String` and processed uniformly. One code path, both shapes, dispatched by `PyAny`'s engine. -/
def firstVowelDyn (x : PyAny) : String := firstVowel ⟨x⟩

#eval firstVowelDyn (.str "yogurt")               -- "o"   (runtime tag = str)
#eval firstVowelDyn (.list (["b","c","a"].map .str))  -- "a"  (runtime tag = list)

open PastaLean in
/-- And it still proves — the postcondition holds for any `PyDyn String`, hence any runtime shape. -/
theorem firstVowel_spec (word : PyDyn String) :
    firstVowel word = "" ∨ isVowel (firstVowel word) = true := by
  unfold firstVowel
  cases h : ((PastaLean.pyIter word).find? (fun ch => isVowel ch)) with
  | none => left; rfl
  | some ch => right; simp only [Option.getD]; exact List.find?_some h

end PastaLean.Examples
