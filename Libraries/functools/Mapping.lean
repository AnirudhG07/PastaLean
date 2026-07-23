import Libraries.functools.FunctoolsDef

namespace Libraries.functools

/-- Map supported `functools` members to the Lean runtime helpers they lower to. -/
def pythonFunctoolsMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "reduce" => some ``Libraries.functools.pyReduce
  | _ => none

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
