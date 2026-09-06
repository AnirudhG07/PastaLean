import Libraries.collections.CollectionsDef
import Libraries.Behaviour

namespace Libraries.collections
open Libraries TypeInfer

/-- Map supported `collections` members to the Lean runtime helpers they lower to.

`Counter`/`defaultdict`/`deque` are normally claimed earlier by their special-call lowerer, which
picks the right constant from the call's arity and factory argument. These entries cover a member
used as a *value* — a `Counter(xs)`/`deque(xs)` constructor reference, or a factory passed to
`defaultdict(deque)` (whose codegen'd arg is discarded, so any resolving name suffices). -/
def pythonCollectionsMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "Counter"     => some ``Libraries.collections.pyCounter
  | "deque"       => some ``Libraries.collections.pyDeque
  | "defaultdict" => some ``Libraries.collections.pyDefaultDictList
  | _ => none

-- `collectionsBehaviour?` (type-inference return shapes) moved to `Libraries/TypeBehaviour.lean`.

end Libraries.collections
