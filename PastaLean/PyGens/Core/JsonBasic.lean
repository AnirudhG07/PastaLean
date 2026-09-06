import Lean

/-!
# JSON AST node-type helpers (Mathlib-free)

Two tiny predicates every IR pass needs — reading a node's `node_type`, and testing whether a subtree
contains one of a set of node types. They live apart from `PyGens/Core/Utils.lean` (which pulls in the
whole codegen environment, and Mathlib with it) so the pure IR transforms — `Desugar`, and through it
the standalone `typeinfer` inference binary — can use them without dragging the runtime into scope.
-/

open Lean

namespace PastaLean

/-- Read the `node_type` tag from a JSON AST node when present. -/
def jsonNodeType? (json : Json) : Option String :=
  json.getObjValAs? String "node_type" |>.toOption

/-- Recursively check whether a JSON subtree contains any node type from `targets`. -/
partial def jsonContainsNodeType (json : Json) (targets : List String) : Bool :=
  let currentMatches :=
    match json.getObjValAs? String "node_type" with
    | .ok nodeType => targets.contains nodeType
    | .error _ => false
  if currentMatches then
    true
  else
    match json with
    | .arr elems => elems.toList.any (fun elem => jsonContainsNodeType elem targets)
    | .obj fields => fields.toList.any (fun (_, value) => jsonContainsNodeType value targets)
    | _ => false

end PastaLean
