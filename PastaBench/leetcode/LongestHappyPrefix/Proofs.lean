import PastaBench.leetcode.LongestHappyPrefix.Generated

/-!
# longest-happy-prefix — hand-written proofs  (Hard, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only LongestHappyPrefix` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem longestPrefix_spec' : <the generated statement> := by
  <hand-written proof>

example : longestPrefix_spec = longestPrefix_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.LongestHappyPrefix

-- TODO: state and prove the correctness theorem for `longestPrefix`.

end PastaBench.leetcode.LongestHappyPrefix
