import PastaLean.Imports

/-!
# Scope-preservation of PastaLean's lambda lifting

This file machine-checks the *provable core* of the nested-definition lifting described in the paper
(§"What Python and Lean change about lambda lifting", Listing `lst:lift-algo`): the free-variable
computation, with its four Python-driven edits, and the transformation's **scope-preservation**
property. A full cross-language semantic equivalence (Python behaviour = compiled-Lean behaviour) would
need formal operational semantics for both sides; that is validated empirically (cp_harness / PALC),
not here. What *is* provable — and is the analogue of what Levy–Reeves prove for their algorithm — is
that the transformation never puts a name out of scope: every name the lifted sibling's body uses
resolves to one of its parameters (its own, or a capture the algorithm added) or to the ambient
globals/builtins/imports that a sibling top-level definition still sees.

We model only what scoping depends on: the finite sets of names a nested function `inner` **uses** and
**binds**, the names its enclosing function `outer` binds (`outerBound`), and the ambient names `Γ`
(module globals, builtins, imports). Names are any type with decidable equality. The four edits and the
"keep globals out" effect all appear as theorems below.

This file is intentionally standalone (imported by nothing), so it does not enter the default build; it
is checked on demand with `lake build PastaLean.PyGens.Transform.LiftingCorrectness`.
-/

namespace PastaLean.Lifting

variable {Name : Type} [DecidableEq Name]

/-- The scope-relevant summary of a nested function `inner`. Each field is the corresponding set of
variable names as the source-level analysis computes it. -/
structure Inner (Name : Type) [DecidableEq Name] where
  /-- `usedVars(inner)`: every name appearing anywhere in `inner`, read or written. -/
  used        : Finset Name
  /-- `inner`'s own declared parameters. -/
  params      : Finset Name
  /-- Names `inner` assigns to (`x = ...`). -/
  assigns     : Finset Name
  /-- Names bound by a comprehension or lambda inside `inner` (the `v` in `[v*2 for v in xs]`). -/
  compTargets : Finset Name
  /-- Names `inner` declares `nonlocal`. -/
  nonlocals   : Finset Name

namespace Inner

variable (I : Inner Name)

/-- `boundVars(inner)` = parameters together with assigned names (the paper's definition). -/
def boundVars : Finset Name := I.params ∪ I.assigns

/-- The free set, computed exactly as Listing `lst:lift-algo`:
`free ← usedVars \ boundVars` (the textbook rule), then edit (1) `\ comprehensionAndLambdaTargets`,
then edit (2) `∪ nonlocals`. -/
def free : Finset Name := ((I.used \ I.boundVars) \ I.compTargets) ∪ I.nonlocals

/-- Captures — edit (3): keep only free names the **enclosing** function itself binds. This is what
keeps module globals, builtins and imports out, since a sibling top-level definition still sees those. -/
def caps (outerBound : Finset Name) : Finset Name := I.free ∩ outerBound

/-- The names genuinely bound *locally* within `inner`, i.e. those its body can use with no capture:
its parameters; the names it assigns that are **not** `nonlocal` (a `nonlocal` assignment aliases the
enclosing binding, it does not create a local); and the comprehension/lambda targets. This is the
notion of "in scope inside `inner`, on `inner`'s own" that the edits are engineered to track. -/
def localBound : Finset Name := I.params ∪ (I.assigns \ I.nonlocals) ∪ I.compTargets

end Inner

open Inner

/-!
## The main result

`inner`, in its original nested position, can see three things: its own local bindings
(`localBound`), whatever the enclosing function binds (`outerBound`), and the ambient `Γ`. So a
well-scoped input satisfies `used ⊆ localBound ∪ outerBound ∪ Γ` (any name outside all three is a
`NameError` in the source). After lifting, the sibling loses access to `outerBound` but gains the
capture parameters `caps outerBound`; its body can therefore see `localBound ∪ caps ∪ Γ`.

Scope preservation is that the second set still covers `used`. -/

/-- **Scope preservation.** If the nested definition was well-scoped in its enclosing context, then the
lifted sibling definition is well-scoped from its own context: every name it uses is either bound
locally, supplied as a capture parameter, or ambient. The enclosing scope `outerBound` has been
replaced by exactly the captures the algorithm added, and nothing slips out of scope. -/
theorem lift_preserves_scope (I : Inner Name) (outerBound Γ : Finset Name)
    (hwf : I.used ⊆ I.localBound ∪ outerBound ∪ Γ) :
    I.used ⊆ I.localBound ∪ I.caps outerBound ∪ Γ := by
  intro x hx
  have hx' := hwf hx
  simp only [Inner.localBound, Inner.caps, Inner.free, Inner.boundVars,
    Finset.mem_union, Finset.mem_inter, Finset.mem_sdiff] at hx hx' ⊢
  tauto

/-!
## Each edit does exactly its job

The four lemmas below pin down what the four edits accomplish for scoping. -/

/-- Captures are always names the enclosing function binds. -/
theorem caps_subset_outer (I : Inner Name) (outerBound : Finset Name) :
    I.caps outerBound ⊆ outerBound := Finset.inter_subset_right

/-- **Edit (3) keeps globals/builtins/imports out.** A purely ambient name — one the enclosing
function does *not* itself bind — is never captured, so it is never turned into a spurious parameter. -/
theorem ambient_not_captured (I : Inner Name) (outerBound Γ : Finset Name)
    {x : Name} (_hΓ : x ∈ Γ) (hout : x ∉ outerBound) : x ∉ I.caps outerBound :=
  fun h => hout (caps_subset_outer I outerBound h)

/-- **Edit (2) captures written `nonlocal` names.** A `nonlocal` name the enclosing function binds is
captured, so the helper receives it (and can hand back its new value). Without edit (2) the textbook
rule would have dropped it, because it is assigned. -/
theorem nonlocal_captured (I : Inner Name) (outerBound : Finset Name) :
    I.nonlocals ∩ outerBound ⊆ I.caps outerBound := by
  intro x hx
  simp only [Inner.caps, Inner.free, Finset.mem_inter, Finset.mem_union] at hx ⊢
  tauto

/-- **Edit (1) never captures a comprehension/lambda target.** As long as a comprehension target is not
also a `nonlocal` name (it never is — it is freshly bound by the comprehension), it is not captured, so
it stays the comprehension's own binding rather than becoming a parameter. -/
theorem compTarget_not_captured (I : Inner Name) (outerBound : Finset Name)
    (hdisj : Disjoint I.compTargets I.nonlocals) :
    Disjoint I.compTargets (I.caps outerBound) := by
  rw [Finset.disjoint_left] at hdisj ⊢
  intro x hx hcap
  rw [Inner.caps] at hcap
  have hfree : x ∈ I.free := Finset.mem_of_mem_inter_left hcap
  rw [Inner.free, Finset.mem_union] at hfree
  rcases hfree with h | h
  · exact (Finset.mem_sdiff.1 h).2 hx
  · exact hdisj hx h

/-!
## Edit (4): the mutation split is a reordering, not a scope change

Edit (4) partitions the captures into read-only and mutated, and emits them as
`ordered = (caps \ mutated) ++ mutated`, threading the mutated ones back on the return. As a *set* the
parameters added are still exactly `caps`, so the split changes the calling convention and the return
type, not what is in scope — the scope-preservation theorem above is unaffected by it. -/

/-- The parameters the helper gains, `(caps \ mutated) ++ mutated`, are as a set exactly `caps`
whenever `mutated ⊆ caps`. So edit (4)'s reordering leaves the captured-name *set* unchanged. -/
theorem ordered_eq_caps (I : Inner Name) (outerBound mutated : Finset Name)
    (hsub : mutated ⊆ I.caps outerBound) :
    (I.caps outerBound \ mutated) ∪ mutated = I.caps outerBound :=
  Finset.sdiff_union_of_subset hsub

end PastaLean.Lifting
