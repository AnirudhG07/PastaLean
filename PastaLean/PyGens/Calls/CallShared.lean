import Mathlib
import PastaLean.Codegen
import PastaLean.PyGens.Basic
import PastaLean.PyGens.Core.Utils
import TypeInfer

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-- Keyword-argument object in Python call JSON. -/
abbrev PyKeywordArgs := Std.TreeMap.Raw String Json compare

/-- The Lean type of a `PyType`, with `float` resolved against the current numeric mode. -/
def pyTypeSyntax? (t : TypeInfer.PyType) : PygenM (Option (TSyntax `term)) := do
  let floatTy : TSyntax `term ← match ← getNumericMode with
    | .exact => pure (mkIdent (if (← getRealContext) then ``Real else ``Rat))
    | .approx => pure (mkIdent ``Float)
  TypeInfer.toTypeSyntax? floatTy t

/-- Split a `defaultdict[k, v]` annotation node into its key and value annotations. -/
def defaultDictAnnParts? (ann : Json) : Option (Json × Json) :=
  if jsonNodeType? ann != some "Subscript" then none
  else match (ann.getObjVal? "value").toOption, (ann.getObjVal? "slice").toOption with
    | some value, some slice =>
        if value.getObjValAs? String "id" != .ok "defaultdict" then none
        else if jsonNodeType? slice != some "Tuple" then none
        else
          let elts := (slice.getObjValAs? (Array Json) "elts").toOption.getD #[]
          match elts[0]?, elts[1]? with
          | some k, some v => some (k, v)
          | _, _ => none
    | _, _ => none

/-- Emit a type from an annotation, honouring the `_seq: "array"` marker the eligibility pass stamps
on each `list[...]` level: an `array_ok` list becomes `Array` (recursively, so `list[list[int]]` →
`Array (Array Int)`) in the runnable twin. The marker has no `PyType` slot, so `pyTypeSyntax? ∘
ofAnnotation` would drop it — hence this reads it off the annotation directly, falling back to the
`PyType` path for un-marked (or non-`list`) levels. -/
partial def seqAwareTypeSyntax? (ann : Json) : PygenM (Option (TSyntax `term)) := do
  let isArrList := (ann.getObjValAs? String "node_type" == .ok "Subscript")
    && ((ann.getObjVal? "value").toOption.any (·.getObjValAs? String "id" |>.toOption |>.any (· == "list")))
    && (ann.getObjValAs? String "_seq" == .ok "array")
  if isArrList && (← getNumericMode) == .approx then
    match ann.getObjVal? "slice" with
    | .ok elemAnn =>
        match ← seqAwareTypeSyntax? elemAnn with
        | some et => return some (← `(Array $et))
        | none => pyTypeSyntax? (TypeInfer.ofAnnotation ann)
    | _ => pyTypeSyntax? (TypeInfer.ofAnnotation ann)
  else pyTypeSyntax? (TypeInfer.ofAnnotation ann)

/-- The Lean type stamped on a node by the inference pass (`_ty`), if any. `_ty` is an annotation
node, so it round-trips through `PyType` and the full emitter — covering lists, dicts, tuples and
`Optional`, not just the shapes the annotation reader handles directly. -/
def stampedTypeSyntax? (node : Json) : PygenM (Option (TSyntax `term)) := do
  match jsonFieldOption node "_ty" with
  | some ann =>
      -- `defaultdict[k, v]` is backed by `PyDefaultDict`; `PyType` models it as a plain dict, so
      -- round-tripping it through the emitter would wrongly yield `Std.HashMap`.
      match defaultDictAnnParts? ann with
      | some (k, v) =>
          match ← pyTypeSyntax? (TypeInfer.ofAnnotation k), ← pyTypeSyntax? (TypeInfer.ofAnnotation v) with
          | some kt, some vt => return some (← `(Libraries.collections.PyDefaultDict $kt $vt))
          | _, _ => return none
      | none => seqAwareTypeSyntax? ann
  | none => return none

/-- Infer a simple runtime type from a value expression when the shape is obvious. -/
def inferSimpleValueTypeSyntax? (json : Json) : PygenM (Option (TSyntax `term)) :=
  pyTypeSyntax? (TypeInfer.ofValue json)

/-- Infer a simple iterable element type from obvious literal iterables. -/
def inferIterableElemTypeSyntax? (json : Json) : PygenM (Option (TSyntax `term)) := do
  -- Iterating a `String` yields `Char`, not a one-character `String`.
  match TypeInfer.ofValue json with
  | .str => return some (mkIdent ``Char)
  | t => pyTypeSyntax? t.elemType

/-- Read the positional parameter names from a lambda node without depending on `FuncDef.lean`. -/
def lambdaArgIdents (json : Json) : PygenM (Array (TSyntax `ident)) := do
  let .ok argsJson := json.getObjValAs? Json "args" | throwError
    s!"Lambda node does not have an 'args' field or it is not a JSON value: {json}"
  let .ok argsArray := argsJson.getObjValAs? (Array Json) "args" | throwError
    s!"Lambda args does not have an 'args' field or it is not a JSON array: {argsJson}"
  argsArray.mapM fun argJson => do
    let .ok argName := argJson.getObjValAs? String "arg" | throwError
      s!"Lambda argument does not have an 'arg' field or it is not a string: {argJson}"
    pure (mkIdent argName.toName)

/--
Stamp a binary lambda with either concrete runtime types or `_` placeholders so overloaded
operators inside higher-order calls elaborate more predictably.
-/
def typedBinaryLambdaCode (funcJson : Json) (fallback : TSyntax `term)
    (paramTy? : Option (TSyntax `term)) : PygenM (TSyntax `term) := do
  unless funcJson.getObjValAs? String "node_type" == .ok "Lambda" do
    return fallback
  let argIdents ← lambdaArgIdents funcJson
  unless argIdents.size == 2 do
    return fallback
  let .ok bodyJson := funcJson.getObjValAs? Json "body" | throwError
    s!"Lambda node does not have a 'body' field or it is not a JSON value: {funcJson}"
  let bodyStx ← getCode bodyJson `term
  let arg0 := argIdents[0]!
  let arg1 := argIdents[1]!
  let paramTy ← match paramTy? with
    | some stx => pure stx
    | none => `(_)
  `(fun ($arg0 : $paramTy) ↦ fun ($arg1 : $paramTy) ↦ $bodyStx)

/-- A value-and-mutate method resolved for its actual argument count: the `(value, rest)` runtime
pair plus how many of the args `rest` consumes (`value` always takes them all). `pop` is
index-based on a list/set (0-1 args) but key-based on a dict (`pop(key, default)`, 2 args); a
2-arg pop is unambiguously the dict form, whose `rest` drops the default and keeps only the key. -/
def valueAndMutateMethod? (attr : String) (argc : Nat) : Option (Lean.Name × Lean.Name × Nat) :=
  match attr with
  | "pop"     =>
      if argc == 2 then some (``PastaLean.pyDictPopValue, ``PastaLean.pyDictPopRest, 1)
      else if argc ≤ 1 then some (``PastaLean.pyPopValue, ``PastaLean.pyPopRest, argc)
      else none
  | "popleft" => if argc == 0 then some (``PastaLean.pyPopLeftValue, ``PastaLean.pyPopLeftRest, 0) else none
  -- `d.setdefault(key, default)`: value is `d[key]`-or-default (`pyGetD`), rest inserts when absent.
  | "setdefault" => if argc == 2 then some (``PastaLean.pyGetD, ``PastaLean.pyDictSetdefaultRest, 2) else none
  | _         => none

/-- Recognize `container.<m>(args…)` for a value-and-mutate method `m` on an already-declared
mutable variable. Returns the runtime pair, the receiver, the value-form args, and the rest-form
args (a prefix). A freshly-seen receiver is not a mutation site, so it returns `none`. -/
def popCallParts? (value : Json) :
    PygenM (Option ((Lean.Name × Lean.Name) × TSyntax `ident × Array (TSyntax `term) × Array (TSyntax `term))) := do
  unless jsonNodeType? value == some "Call" do return none
  let .ok funcJson := value.getObjVal? "func" | return none
  unless jsonNodeType? funcJson == some "Attribute" do return none
  let .ok attr := funcJson.getObjValAs? String "attr" | return none
  let args := (value.getObjValAs? (Array Json) "args").toOption.getD #[]
  let some (valueFn, restFn, restArgc) := valueAndMutateMethod? attr args.size | return none
  let .ok receiverJson := funcJson.getObjVal? "value" | return none
  unless jsonNodeType? receiverJson == some "Name" do return none
  let receiverIdent ← getCode receiverJson `ident
  unless (← hasVar receiverIdent.getId) do return none
  let argCodes ← args.mapM (getCode · `term)
  return some ((valueFn, restFn), receiverIdent, argCodes, argCodes.extract 0 restArgc)

/-- Lower a call that both mutates its receiver and yields a value into a `(value, update)`
pair. They each read the *original* container, so the caller binds `value` first, then runs
`update`. Covers `container.pop(idx?)` and `deque.popleft()`. -/
def mutatingCallRhsLowering? (value : Json) :
    PygenM (Option (TSyntax `term × TSyntax `doElem)) := do
  match ← popCallParts? value with
  | none =>
      -- A library member that both mutates its first arg and returns a value (`x = heapq.heappop(h)`),
      -- read from the `Libraries` mutator spec so no library names live in codegen.
      match (value.getObjVal? "func").toOption.bind libraryMutatorOf? |>.bind (·.valueRest?) with
      | some (valFn, restFn) =>
          match value.getObjValAs? (Array Json) "args" with
          | .ok args =>
              if args.size ≥ 1 && jsonNodeType? args[0]! == some "Name" then
                let recvIdent ← getCode args[0]! `ident
                let argsCodes ← args.mapM (getCode · `term)
                let valueTerm ← `($(mkIdent valFn) $argsCodes*)
                let update ← `(doElem| $recvIdent:ident := $(mkIdent restFn) $argsCodes*)
                return some (valueTerm, update)
              else return none
          | _ => return none
      | none => return none
  | some ((valueFn, restFn), receiverIdent, valueArgs, restArgs) =>
      let valueIdent := mkIdent valueFn
      let restIdent := mkIdent restFn
      let valueTerm ← `($valueIdent $receiverIdent $valueArgs*)
      let update ← `(doElem| $receiverIdent:ident := $restIdent $receiverIdent $restArgs*)
      return some (valueTerm, update)

end PastaLean
