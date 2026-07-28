import PastaBench.leetcode.CuttingRibbons.Generated

/-!
# cutting-ribbons — hand-written proofs  (Medium, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only CuttingRibbons` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem maxLength_spec' : <the generated statement> := by
  <hand-written proof>

example : maxLength_spec = maxLength_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.CuttingRibbons

-- TODO: state and prove the correctness theorem for `maxLength`.

end PastaBench.leetcode.CuttingRibbons
