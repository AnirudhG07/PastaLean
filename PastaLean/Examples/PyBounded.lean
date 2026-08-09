import PastaLean

/-!
# Bounded parametric polymorphism — the *constructable* answer

`PyStrSeq` (a bespoke wrapper) and `PyOneOf` (a bespoke enum + type-valued function) both work, but you
correctly noted they don't scale: you'd hand-build one per shortlist (`str|list[str]`, `int|float`,
`list[int]|set[int]`, …). The scalable, **open** encoding is the standard one from the literature —
*bounded quantification / type-class-bounded polymorphism* (Wadler–Blott; Castagna's gradual
set-theoretic types treat the dynamic `?` as a union materialisable to a bounded one). The ambiguous
parameter becomes **polymorphic, constrained by exactly the protocols its body uses**. Any candidate
type "constructs into" the bound simply by having those instances — no union, no wrapper, no enum, and
it's open (add a candidate ⇒ add an instance).

Crucially, PastaLean *already* has the instances, for both readings, with the **same** element type
(Python iterates a `str` into 1-char `String`s): `PyIterable String String`, `PyIterable (List String)
String`, `PyGetItem String Int String`, `PyLen String`, … So nothing new is defined here — the bound is
just the conjunction of the protocols the body touches.
-/

namespace PastaLean.Examples

def isVowel (ch : String) : Bool := ["a","e","i","o","u","A","E","I","O","U"].contains ch

/-! ### Form 1 — constrain by the exact protocols the body uses (minimal, fully inferred) -/

open PastaLean in
/-- `word` is any type you can iterate into `String`s. `str` and `list[str]` both qualify; so would a
future `tuple[str]`, for free. The element `ch : String` is concrete, so `isVowel ch` typechecks —
the thing `PyAny` cannot deliver. -/
def firstVowel {α : Type} [PastaLean.PyIterable α String] (word : α) : String :=
  ((PastaLean.pyIter word).find? (fun ch => isVowel ch)).getD ""

#eval firstVowel "yogurt"              -- "o"   (word : String)
#eval firstVowel ["b", "c", "a", "e"]  -- "a"   (word : List String)

open PastaLean in
/-- One proof, universally quantified over the type AND its interface instance — it therefore covers
every candidate that ever satisfies the bound, present or future. No per-tag split, no `PyAny`. -/
theorem firstVowel_spec {α : Type} [PastaLean.PyIterable α String] (word : α) :
    firstVowel word = "" ∨ isVowel (firstVowel word) = true := by
  unfold firstVowel
  cases h : ((PastaLean.pyIter word).find? (fun ch => isVowel ch)) with
  | none => left; rfl
  | some ch => right; simp only [Option.getD]; exact List.find?_some h

/-! ### Form 2 — a general, element-parametric interface class

`PySeq α elem` = "α is an int-indexable Python sequence whose elements are `elem`". `elem` is an
`outParam` fixed by the container, so it generalises far past `String`: a **single** generic instance
`PySeq (List α) α` admits `List Int`, `List String`, `List PyAny`, … , and `PySeq String String`
admits `str`. Membership is *constructable* — any type with the parent protocol instances joins by
`:= {}`, reusing what PastaLean already has; nothing bespoke per shortlist. -/

class PySeq (α : Type) (elem : outParam Type) extends
    PastaLean.PyLen α, PastaLean.PyGetItem α Int elem, PastaLean.PyIterable α elem, PastaLean.PyTruthy α

/-- One generic instance covers EVERY list element type — `List Int`, `List PyAny`, `List String`, … -/
instance {α : Type} [Inhabited α] : PySeq (List α) α := {}
/-- …and `str` joins as a sequence of 1-char strings. -/
instance : PySeq String String := {}

open PastaLean in
/-- Generic over any `PySeq`: `str`, `list[str]`, `list[int]`, `list[PyAny]` — including the dynamic
`PyAny` element case, which is a *subtype* of the bound, not an escape from it. -/
def firstMatching {α elem : Type} [PySeq α elem] (word : α) (p : elem → Bool) : Option elem :=
  (PastaLean.pyIter word).find? p

#eval firstMatching "banana" isVowel                       -- some "a"   (str, elem String)
#eval firstMatching ["x", "e", "y"] isVowel                -- some "e"   (List String)
#eval firstMatching ([3, 7, 4, 9] : List Int) (fun n : Int => n % 2 == 0)  -- some 4   (List Int, elem Int)
#eval (firstMatching ([(1 : PyAny), "a", (2 : PyAny)]) (fun _ => true)).isSome  -- true (List PyAny)

/-! ### Form 3 — the SHORTLIST carried in the type (`A ⊕ B`), interface forwarded

Bounded polymorphism (Forms 1–2) is *open* — any conforming type. If instead you want the concrete
type to *name exactly* the candidates (your `PySeq Int String` idea — "it is one of these"), carry the
shortlist in the type as `A ⊕ B` and FORWARD each protocol whenever BOTH candidates provide it with the
same result types. Then `String ⊕ List String` is a real, closed type that still supports the whole
`PySeq` interface — reusing PastaLean's instances, nothing per-shortlist. -/

instance {A B : Type} [PastaLean.PyLen A] [PastaLean.PyLen B] : PastaLean.PyLen (A ⊕ B) where
  pyLen := Sum.elim PastaLean.pyLen PastaLean.pyLen
instance {A B ι elem : Type} [PastaLean.PyGetItem A ι elem] [PastaLean.PyGetItem B ι elem] :
    PastaLean.PyGetItem (A ⊕ B) ι elem where
  getItem x i := x.elim (PastaLean.pyGetItem · i) (PastaLean.pyGetItem · i)
instance {A B elem : Type} [PastaLean.PyIterable A elem] [PastaLean.PyIterable B elem] :
    PastaLean.PyIterable (A ⊕ B) elem where
  toPyList := Sum.elim PastaLean.pyIter PastaLean.pyIter
instance {A B : Type} [PastaLean.PyTruthy A] [PastaLean.PyTruthy B] : PastaLean.PyTruthy (A ⊕ B) where
  truthy := Sum.elim PastaLean.pyTruthy PastaLean.pyTruthy
/-- So `A ⊕ B` is a `PySeq` whenever both candidates are — the shortlist `{A, B}` lives in the type. -/
instance {A B elem : Type} [PySeq A elem] [PySeq B elem] : PySeq (A ⊕ B) elem := {}

/-! ### Union vs type-valued function — the relationship (your prof is right)

`A ⊕ B` (Form 3) IS a union — a *disjoint/tagged* one (coproduct): the tag lives in the value, and every
use unwraps `.inl`/`.inr`. A disjoint union is exactly the **special case** of a type-valued function
(`LengthMultiReturn.lean`'s `funWithLengthType`) whose tag type is `Bool` — `A ⊕ B ≅ Σ b : Bool, choose b`.
The type-function generalises what a fixed binary `⊕` cannot: any tag type, any arity, a *computed*
type, and — when the tag is known — the value is the NATIVE type (a real `String`), not a wrapped `.inl`. -/

/-- The type-valued function; `A ⊕ B` is this with the tag baked in as `Bool`. -/
def choose : Bool → Type | true => String | false => List String

/-- A disjoint union carries the SAME data as `Σ tag, (chosen type)` — the tag plus a value of it. -/
def ofSum : String ⊕ List String → Σ b : Bool, choose b
  | .inl s => ⟨true, s⟩
  | .inr l => ⟨false, l⟩
def toSum : (Σ b : Bool, choose b) → String ⊕ List String
  | ⟨true, s⟩  => .inl s
  | ⟨false, l⟩ => .inr l

/-- The type-function idates (a union would right-nest `⊕` awkwardly), and
`chooseK .a` is *literally* `String` — no wrapper. -/
inductive Tag3 | a | b | c
def chooseK : Tag3 → Type | .a => String | .b => List String | .c => List Int
#check (("abc" : chooseK .a))            -- accepted: chooseK .a reduces to String, the value is native

/-! ### Real HumanEval bodies that today box to `PyAny`, done with the bound instead -/

def isUpperVowel (ch : String) : Bool := ["A","E","I","O","U"].contains ch

open PastaLean in
/-- **HumanEval `count_upper`** (currently `s : PyAny`). `s` is used only as `len(s)` and `s[i]`
(a `String`, tested against `"AEIOU"`) — the textbook `str`-vs-`list[str]` ambiguity. Bounded by
`PySeq α String`, the SAME code counts for a real `str` and a real `list[str]`, and `s[i] : String`
so the vowel test typechecks (which it cannot when `s[i] : PyAny`). -/
def countUpper {α : Type} [PySeq α String] (s : α) : Int :=
  (List.range (PastaLean.pyLen s).toNat).foldl
    (fun cnt i => if i % 2 == 0 && isUpperVowel (PastaLean.pyGetItem s (i : Int)) then cnt + 1 else cnt) 0

#eval countUpper "aBCdEf"                    -- 1   (str, via `[PySeq String String]`)
#eval countUpper ["a","B","C","d","E","f"]   -- 1   (list[str], identical result)
-- ...or against the CLOSED shortlist type `String ⊕ List String` (Form 3) — same code, both injections:
#eval countUpper (Sum.inl "aBCdEf" : String ⊕ List String)                   -- 1
#eval countUpper (Sum.inr ["a","B","C","d","E","f"] : String ⊕ List String)  -- 1

/-- Its postcondition (`count ≥ 0`) is proved once, generically over the bound. -/
theorem countUpper_nonneg {α : Type} [PySeq α String] (s : α) : 0 ≤ countUpper s := by
  unfold countUpper
  suffices h : ∀ (l : List Nat) (c : Int), 0 ≤ c →
      0 ≤ l.foldl (fun cnt i =>
        if i % 2 == 0 && isUpperVowel (PastaLean.pyGetItem s (i : Int)) then cnt + 1 else cnt) c by
    exact h _ 0 (le_refl 0)
  intro l
  induction l with
  | nil => intro c hc; exact hc
  | cons x xs ih => intro c hc; apply ih; beta_reduce; split <;> omega

open PastaLean in
/-- **HumanEval `pluck`**-shaped (currently `arr : PyAny`): the element is used as an `int` (`val % 2`),
so this is `PySeq α Int` — the SAME machinery with `elem := Int`. Smallest even value, or `none`. -/
def smallestEven {α : Type} [PySeq α Int] (arr : α) : Option Int :=
  ((PastaLean.pyIter arr).filter (fun v => v % 2 == 0)).foldl
    (fun acc v => match acc with | none => some v | some m => some (min m v)) none

#eval smallestEven ([5, 3, 8, 2, 6] : List Int)   -- some 2   (List Int)
#eval smallestEven ([1, 3, 5] : List Int)         -- none

/-! `PyAny` is the ⊤ of this lattice: when a parameter's uses share no coherent bound — e.g. a body
that indexes it BOTH by `Int` and by a string key (str-vs-dict, which have incompatible `PyGetItem`
index types) — no `PySeq`/sibling interface applies, and inference falls back to plain `PyAny` (whose
own `pyany_cases` handles it). A dict is served by a sibling `PyMap α key val` bundle (it iterates keys
but indexes values, so it can't reuse `PySeq`'s single `elem`); the same "reuse existing instances via
`:= {}`" recipe builds it. -/

end PastaLean.Examples
