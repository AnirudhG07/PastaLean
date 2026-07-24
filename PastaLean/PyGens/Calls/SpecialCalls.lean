import PastaLean.PyGens.Calls.SpecialCalls.Collections
import PastaLean.PyGens.Calls.SpecialCalls.Functools
import PastaLean.PyGens.Calls.SpecialCalls.Itertools
import PastaLean.PyGens.Calls.SpecialCalls.LibraryMutators

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-- The bare-name func for a qualified call on a star-imported flat library module
(`collections.deque`, `heapq.heappush`, `itertools.chain`, …). These modules are `from X import *`
in the corpus preamble, so `mod.member(args)` is the same call as bare `member(args)`; returning the
bare `Name` lets a special lowerer that matches the bare name also claim the qualified form. Members
with no special lowerer just return `none` and fall through to the regular member map. -/
private def bareLibraryFunc? (funcJson : Json) : Option Json :=
  if jsonNodeType? funcJson != some "Attribute" then none else
  match funcJson.getObjValAs? String "library_module" |>.toOption,
        funcJson.getObjValAs? String "library_member" |>.toOption with
  | some mod, some member =>
      if #["collections", "heapq", "itertools", "functools"].contains mod then
        some (Json.mkObj [("node_type", .str "Name"), ("id", .str member), ("ctx", .str "Load")])
      else none
  | _, _ => none

/-- Try each registered special term-level call lowerer until one claims the call. A qualified
flat-library call (`collections.deque(…)`) is retried on its bare name so it dispatches like `deque(…)`. -/
def lowerSpecialCallTerm? (funcJson : Json) (argsArray : Array Json) (argsCodes : Array (TSyntax `term))
    (keyWordsMap : PyKeywordArgs) : PygenM (Option (TSyntax `term)) := do
  let tryOn (fj : Json) : PygenM (Option (TSyntax `term)) := do
    match ← lowerFunctoolsCallTerm? fj argsArray argsCodes keyWordsMap with
    | some lowered => return some lowered
    | none =>
    match ← lowerItertoolsCallTerm? fj argsArray argsCodes keyWordsMap with
    | some lowered => return some lowered
    | none => lowerCollectionsCallTerm? fj argsArray argsCodes keyWordsMap
  match ← tryOn funcJson with
  | some lowered => return some lowered
  | none => match bareLibraryFunc? funcJson with
    | some bare => tryOn bare
    | none => return none

/-- Try each registered special `doElem` call lowerer until one claims the call. Qualified flat-library
calls are retried on their bare name (so `heapq.heappush(h, x)` dispatches like `heappush(h, x)`). -/
def lowerSpecialCallDoElem? (funcJson : Json) (argsArray : Array Json) (argsCodes : Array (TSyntax `term))
    (keyWordsMap : PyKeywordArgs) : PygenM (Option (TSyntax `doElem)) := do
  let tryOn (fj : Json) : PygenM (Option (TSyntax `doElem)) := do
    match ← lowerFunctoolsCallDoElem? fj argsArray argsCodes keyWordsMap with
    | some lowered => return some lowered
    | none =>
    match ← lowerLibraryMutatorDoElem? fj argsArray argsCodes keyWordsMap with
    | some lowered => return some lowered
    | none => lowerItertoolsCallDoElem? fj argsArray argsCodes keyWordsMap
  match ← tryOn funcJson with
  | some lowered => return some lowered
  | none => match bareLibraryFunc? funcJson with
    | some bare => tryOn bare
    | none => return none

/-- info: 2 -/
#guard_msgs in
#eval 1+1

end PastaLean
