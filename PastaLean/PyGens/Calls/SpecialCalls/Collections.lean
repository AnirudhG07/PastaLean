import Libraries.collections.CollectionsDef
import Libraries.sortedcontainers.SortedListDef
import PastaLean.PyGens.Calls.CallEffects
import PastaLean.PyGens.Calls.CallShared

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-- The `collections` member this call targets, if any: `Counter(...)` / `defaultdict(...)`. -/
def collectionsMember? (json : Json) : Option String :=
  match json.getObjValAs? String "library_module", json.getObjValAs? String "library_member" with
  | .ok "collections", .ok member => some member
  | _, _ =>
      if json.getObjValAs? String "node_type" == .ok "Attribute"
         && (json.getObjValAs? Json "value").toOption.any (fun v =>
              v.getObjValAs? String "node_type" == .ok "Name"
              && v.getObjValAs? String "id" == .ok "collections") then
        (json.getObjValAs? String "attr").toOption
      else none

/-- The bare name of a `defaultdict` factory argument: `defaultdict(list)` ↦ `"list"`. -/
private def factoryName? (argJson : Json) : Option String :=
  if argJson.getObjValAs? String "node_type" == .ok "Name" then
    (argJson.getObjValAs? String "id").toOption
  else none

/-- Lower `Counter()` / `Counter(xs)` / `defaultdict(list)` / `defaultdict(int)`. -/
def lowerCollectionsCallTerm? (funcJson : Json) (argsArray : Array Json)
    (argsCodes : Array (TSyntax `term)) (keyWordsMap : PyKeywordArgs) :
    PygenM (Option (TSyntax `term)) := do
  -- `SortedList()` (sortedcontainers): empty vs. from-iterable, chosen by arity (the from-iterable
  -- form sorts its argument; the empty form needs a distinct nullary constant).
  if funcJson.getObjValAs? String "library_member" == .ok "SortedList" then
    unless keyWordsMap.isEmpty do throwError "SortedList() keyword arguments are not supported yet."
    match argsArray.size with
    | 0 => return some (← `($(mkIdent ``Libraries.sortedcontainers.pySortedListEmpty)))
    | 1 => return some (← buildIOPureApplicationFromArgs argsArray argsCodes fun r => do
             `($(mkIdent ``Libraries.sortedcontainers.pySortedList) $(r[0]!)))
    | _ => throwError "SortedList() expects at most one positional argument."
  let some member := collectionsMember? funcJson | return none
  match member with
  | "Counter" =>
      unless keyWordsMap.isEmpty do
        throwError "Counter() keyword arguments are not supported yet."
      match argsArray.size with
      | 0 => return some (← `($(mkIdent ``Libraries.collections.pyCounterEmpty)))
      | 1 =>
          let counterIdent := mkIdent ``Libraries.collections.pyCounter
          return some (← buildIOPureApplicationFromArgs argsArray argsCodes fun r => do
            `($counterIdent $(r[0]!)))
      | _ => throwError "Counter() expects at most one positional argument."
  | "defaultdict" =>
      unless keyWordsMap.isEmpty do
        throwError "defaultdict() keyword arguments are not supported yet."
      -- Bare `defaultdict()` has NO factory: a missing key raises `KeyError`, exactly like a plain
      -- dict. Lower to the empty dict `{}` (its key/value types come from TypeInfer / later writes).
      let some argJson := argsArray[0]?
        | return some (← `($(mkIdent ``Std.HashMap.ofList) []))
      -- `defaultdict(lambda: <expr>)`: each missing key reads as `<expr>` (`lambda: 1`, `lambda: inf`,
      -- `lambda: [0]*m`). Modelled by `PyDefaultDict.empty <expr>` — the default is evaluated once at
      -- construction rather than lazily per key, which agrees for a constant/closed default.
      if jsonNodeType? argJson == some "Lambda" then
        let .ok body := argJson.getObjVal? "body"
          | throwError "defaultdict(lambda …) is missing a 'body'."
        let bodyCode ← getCode body `term
        return some (← `($(mkIdent ``Libraries.collections.PyDefaultDict.empty) $bodyCode))
      match factoryName? argJson with
      -- Sets and deques are `List`-backed in the runtime, so they share the empty-list default
      -- (`defaultdict(deque)` — each missing key starts an empty deque `[]`, e.g. `pos[a].append(b)`).
      | some "list" | some "set" | some "deque" =>
          return some (← `($(mkIdent ``Libraries.collections.pyDefaultDictList)))
      | some "int"  => return some (← `($(mkIdent ``Libraries.collections.pyDefaultDictInt)))
      | some "dict" => return some (← `($(mkIdent ``Libraries.collections.pyDefaultDictDict)))
      | some "Counter" => return some (← `($(mkIdent ``Libraries.collections.pyDefaultDictCounter)))
      | other =>
          throwError s!"defaultdict({other.getD "?"}) is not supported; only `list`, `set`, `int`, \
            `dict` and `Counter` default factories are."
  | "deque" =>
      unless keyWordsMap.isEmpty do
        throwError "deque() keyword arguments are not supported yet."
      match argsArray.size with
      | 0 => return some (← `($(mkIdent ``Libraries.collections.pyDequeEmpty)))
      | 1 =>
          let dequeIdent := mkIdent ``Libraries.collections.pyDeque
          return some (← buildIOPureApplicationFromArgs argsArray argsCodes fun r => do
            `($dequeIdent $(r[0]!)))
      | _ => throwError "deque() expects at most one positional argument."
  | _ => return none

end PastaLean
