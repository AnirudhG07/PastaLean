import Libraries.functools.FunctoolsDef
import Libraries.Behaviour

namespace Libraries.functools
open Libraries

/-- Map supported `functools` members to the Lean runtime helpers they lower to. -/
def pythonFunctoolsMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "reduce" => some ``Libraries.functools.pyReduce
  | "cmp_to_key" => some ``Libraries.functools.pyCmpToKey
  | _ => none

-- `functoolsBehaviour?` (type-inference return shapes) moved to `Libraries/TypeBehaviour.lean`.

/-- Methods added by `@cache`/`@lru_cache` that lower to a no-op (see `pyCacheNoop`). -/
def functoolsNoopMethod? (member : String) : Option Lean.Name :=
  match member with
  | "cache_clear" | "cache_info" => some ``Libraries.functools.pyCacheNoop
  | _ => none

/-- functools decorators that are transparent to the transpiled value: memoization (`cache`,
`lru_cache`) recomputes to the same result, and `wraps` only copies metadata. So the decorated
function is emitted unchanged. Bare or module-qualified (`functools.cache`) — the caller passes the
last dotted segment. -/
def functoolsTransparentDecorator? (name : String) : Bool :=
  match name with
  | "cache" | "lru_cache" | "wraps" => true
  | _ => false

end Libraries.functools
