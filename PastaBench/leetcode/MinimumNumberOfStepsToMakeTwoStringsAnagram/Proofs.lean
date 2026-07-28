import PastaBench.leetcode.MinimumNumberOfStepsToMakeTwoStringsAnagram.Generated

/-!
# minimum-number-of-steps-to-make-two-strings-anagram — hand-written proofs  (Medium, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only MinimumNumberOfStepsToMakeTwoStringsAnagram` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem minSteps_spec' : <the generated statement> := by
  <hand-written proof>

example : minSteps_spec = minSteps_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.MinimumNumberOfStepsToMakeTwoStringsAnagram

-- TODO: state and prove the correctness theorem for `minSteps`.

end PastaBench.leetcode.MinimumNumberOfStepsToMakeTwoStringsAnagram
