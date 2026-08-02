import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.PrimeFib

/-!
`prime_fib` relies on `random.randint` and Python's 3-argument `pow` (modular
exponentiation) inside a Miller–Rabin primality test. Both are unsupported by
PastaLean (nondeterministic RNG / 3-arg `pow`), so the function degrades to
`pyUnsupported` placeholders and cannot be characterized. We therefore only record
the intended reference behavior as data and prove a trivial specification. -/

/-- The reference output of `prime_fib` on inputs `1..5` (documentation only). -/
def reference : List (Int × Int) := [(1, 2), (2, 3), (3, 5), (4, 13), (5, 89)]

theorem prime_fib_stub : reference.length = 5 := by native_decide

end PastaBench.humaneval.PrimeFib
