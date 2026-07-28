import PastaLean.PyGens.Calls.CallEffects
import PastaLean.PyGens.Calls.CallShared
import PastaLean.PyGens.Core.Assign

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-- Lower a library mutator used AS A STATEMENT (`heapq.heappush(h, x)`, `heapify(h)`, or a discarded
`heappop(h)`) to a rebuild of its first argument — `h := stmtFn h …`. The spec comes from `Libraries`
(`libraryMutatorOf?`), so no library names appear here. The first argument may be a plain variable, a
subscript (`heappush(d[v], x)` → rebuild `d`), or an attribute (`heappush(self.small, x)` → record
update); anything else falls through to the generic path. -/
def lowerLibraryMutatorDoElem? (funcJson : Json) (argsArray : Array Json) (argsCodes : Array (TSyntax `term))
    (_kw : PyKeywordArgs) : PygenM (Option (TSyntax `doElem)) := do
  let some spec := libraryMutatorOf? funcJson | return none
  unless argsArray.size ≥ 1 do return none
  let arg0 := argsArray[0]!
  let fn := mkIdent spec.stmtFn
  -- The rebuilt value reads the ORIGINAL first argument (`argsCodes[0]` is its term), then reassigns
  -- whatever lvalue it is.
  let newVal ← `($fn $argsCodes*)
  match jsonNodeType? arg0 with
  | some "Name" =>
      let hIdent ← getCode arg0 `ident
      return some (← `(doElem| $hIdent:ident := $newVal))
  | some "Subscript" => nestedSubscriptSetDoElem? arg0 newVal
  | some "Attribute" =>
      if (selfAttrTarget? arg0).isSome && (← hasVar `self) then
        return some (← selfRecordUpdateDoElem (selfAttrTarget? arg0).get! newVal)
      let .ok recv := arg0.getObjVal? "value" | return none
      let .ok attr := arg0.getObjValAs? String "attr" | return none
      return some (← attrRecordUpdateDoElem recv attr newVal (arg0.getObjValAs? Bool "_unwrap_opt" == .ok true))
  | _ => return none

end PastaLean
