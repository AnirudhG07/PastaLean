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

/-- Return-type behaviour of `collections` constructors: `Counter(xs)` is a `dict[elem, int]`;
`deque(xs)` a list of `xs`'s element; `OrderedDict(d)` passes its dict through. (`defaultdict` reads
its factory ARGUMENT's name, not a type, so it stays in the engine's `builtinReturn`.) -/
def collectionsBehaviour? (member : String) : Option Behaviour :=
  open Behaviour in
  match member with
  | "Counter"     => some (counterOf 0)
  | "OrderedDict" => some (argType 0)
  | "deque"       => some (listOf 0)
  | _ => none

end Libraries.collections
