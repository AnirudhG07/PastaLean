import PastaBench.stdlib.CPython.Generated

/-!
# CPython standard-library algorithms — hand-written proofs

HUMAN-WRITTEN. Regeneration only rewrites `Generated.lean`; this file is never touched by `regen`.

The `while`-track now emits **native Lean `while` loops**, verified with `mvcgen` (`Spec.whileM` /
`Spec.forIn` over `Lean.Loop`). Each generated `*_spec` theorem is left as `mvcgen [...]; sorry;
all_goals sorry` — fill those `sorry`s here by restating the spec and supplying the loop invariant:

```lean
theorem gcd_spec' : ⦃⌜a ≥ 0 ∧ b ≥ 0⌝⦄ gcd a b ⦃⇓x => ⌜x ≥ 0⌝⦄ := by
  mvcgen [gcd] invariants · ⇓ c => ⌜(match c with | .inl s => …) ⌝
  …
```

(The previous `pyWhile`-combinator proofs were retired together with the combinator.)
-/

namespace PastaBench.stdlib.CPython

open PastaLean

-- Proofs to be filled in against the native-`while` generated defs.

end PastaBench.stdlib.CPython
