import PastaBench.leetcode.JumpGameIv.Generated

/-!
# jump-game-iv — hand-written proofs  (Hard, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Worked reference: `PastaBench/leetcode/SmallestEvenMultiple/Proofs.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only JumpGameIv` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem minJumps_spec' : <the generated statement> := by
  <hand-written proof>

example : minJumps_spec = minJumps_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.JumpGameIv

-- TODO: state and prove the correctness theorem for `minJumps`.

end PastaBench.leetcode.JumpGameIv
