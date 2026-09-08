import PastaLean.Imports

/-!
# Extended rationals — a PROVABLE `inf` that lowers with no runtime refactor

The exact-mode runtime represents `float('inf')` as a finite `ℚ` sentinel (`pyRatNonFinite = 10³⁰`):
it *executes* the `best = inf; best = min(best, …)` idiom, but a finite value can never satisfy
`∀ x, x ≤ inf`, so it carries none of infinity's order structure and admits no proof.

`XRat := WithBot (WithTop ℚ)` fixes that with **no full refactor**: it is `Option`-based, so it stays
**computable** (unlike `EReal`, which pulls in `ℝ` and is `noncomputable`), yet has a genuine top and
bottom with `le_top`/`bot_le` proven, and `min`/`max`/`+`/`≤` come from Mathlib for free. So `INF` is
"just an abbrev of something": codegen can emit `INF` for `float('inf')` and type the slot as `XRat`
(coercing finite `ℚ` values with `↑`), and a proof gets `le_INF : ∀ x, x ≤ INF` for that same term —
only the `inf`-bearing values change type, the rest of the program stays `ℚ`.

TODO (codegen wiring — NOT done yet): make codegen emit `INF`/`NEGINF` automatically. Needs a
`PyType.xrat` variant that TypeInfer assigns to `inf`-bearing variables, codegen lowering
`float('inf')`/`float('-inf')` to `INF`/`NEGINF` with `↑` coercions on the finite `ℚ` values, and
`PastaLean`-protocol instances (`PyHAdd`/`pyMin`/`pyMax`/comparison) for `XRat`. Until then `INF` is an
opt-in primitive a contract can reference directly; plain execution keeps the computable sentinel/Float
paths.
-/

namespace PastaLean

/-- Extended rationals with genuine `±∞`. `WithBot (WithTop ℚ)` — `Option`-based, hence computable. -/
abbrev XRat := WithBot (WithTop ℚ)

/-- Python `float('inf')` as the genuine GREATEST value of `XRat`. Lowers to `⊤ = some none`. -/
def INF : XRat := ⊤

/-- Python `float('-inf')` as the genuine LEAST value of `XRat`. Lowers to `⊥ = none`. -/
def NEGINF : XRat := ⊥

/-- Lift a finite rational into `XRat` (the boundary coercion codegen inserts for finite values). -/
@[coe] def XRat.ofRat (q : ℚ) : XRat := ((q : WithTop ℚ) : XRat)
instance : Coe ℚ XRat := ⟨XRat.ofRat⟩

/-! ## The theorems a user gets when proving with `INF` -/

/-- **`INF` is the greatest:** every extended rational — in particular every finite value that flows
through a `min`/comparison against it — is `≤ INF`. This is what the finite sentinel cannot give. -/
@[simp] theorem le_INF (x : XRat) : x ≤ INF := le_top

/-- **`NEGINF` is the least.** -/
@[simp] theorem NEGINF_le (x : XRat) : NEGINF ≤ x := bot_le

/-- Every finite rational is (strictly) below `INF`. -/
theorem ofRat_lt_INF (q : ℚ) : XRat.ofRat q < INF := by
  simp only [INF, XRat.ofRat]; exact lt_top_iff_ne_top.2 (by simp)

/-- `INF` absorbs `min`: `min x INF = x`. So `best = INF; best = min(best, xᵢ)` ends at the minimum of
the finite values — proved, not just executed. -/
@[simp] theorem min_INF (x : XRat) : min x INF = x := by simp
@[simp] theorem INF_min (x : XRat) : min INF x = x := by simp

/-- `NEGINF` absorbs `max`. -/
@[simp] theorem max_NEGINF (x : XRat) : max x NEGINF = x := by simp
@[simp] theorem NEGINF_max (x : XRat) : max NEGINF x = x := by simp

/-- `INF` is UNIQUELY the greatest (antisymmetry): anything dominating everything equals it. -/
theorem INF_unique (t : XRat) (h : ∀ x, x ≤ t) : t = INF := le_antisymm (le_INF t) (h INF)

/-! ## The payoff: a `min`-reduction seeded at `INF` is provably a lower bound

This is the shape codegen emits for `best = float('inf'); for x in xs: best = min(best, x)` — and now
its postcondition (`best ≤` every element) is *provable*, which the finite sentinel made impossible. -/

/-- Fold `min` over `xs` starting from `INF` (the generated reduction). -/
def minReduce (xs : List XRat) : XRat := xs.foldl min INF

/-- A `min`-fold is bounded by its accumulator AND by every element folded in. -/
theorem foldl_min_le : ∀ (xs : List XRat) (acc : XRat),
    (xs.foldl min acc ≤ acc) ∧ (∀ x ∈ xs, xs.foldl min acc ≤ x)
  | [], acc => ⟨le_refl _, by simp⟩
  | y :: ys, acc => by
      have ih := foldl_min_le ys (min acc y)
      refine ⟨?_, ?_⟩
      · calc (y :: ys).foldl min acc = ys.foldl min (min acc y) := rfl
          _ ≤ min acc y := ih.1
          _ ≤ acc := min_le_left _ _
      · intro x hx
        rcases List.mem_cons.1 hx with heq | hmem
        · rw [heq]
          calc (y :: ys).foldl min acc = ys.foldl min (min acc y) := rfl
            _ ≤ min acc y := ih.1
            _ ≤ y := min_le_right _ _
        · exact ih.2 x hmem

/-- **The reduction is a genuine lower bound:** every element dominates the result. Provable *because*
`INF` is a true top (the `INF` seed never spuriously beats a real value — impossible with the finite
`10³⁰` sentinel). -/
theorem minReduce_le (xs : List XRat) : ∀ x ∈ xs, minReduce xs ≤ x :=
  (foldl_min_le xs INF).2

end PastaLean
