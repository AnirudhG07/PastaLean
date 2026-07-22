import PastaBench.leetcode.PowerOfHeroes.Generated

/-!
# power-of-heroes — hand-written proofs  (Hard, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only PowerOfHeroes` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem sumOfPower_spec' : <the generated statement> := by
  <hand-written proof>

example : sumOfPower_spec = sumOfPower_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.PowerOfHeroes

-- TODO: state and prove the correctness theorem for `sumOfPower`.

end PastaBench.leetcode.PowerOfHeroes
