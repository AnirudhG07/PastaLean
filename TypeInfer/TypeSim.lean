import TypeInfer
import PastaLean.PyGens.Core.JsonBasic

/-!
# TypeSim scoring (in Lean)

A faithful port of TypyBench's `get_type_similarity` (ICML 2025), so predictions can be scored locally
without its mypy/Docker eval. The structural algorithm is exact: a union or an argument list is matched
by an OPTIMAL assignment (brute-force over permutations for the small lists that occur; greedy past
that), scores combine per level, and a one-sided argument list halves the score. The one mypy-dependent
piece — `_get_type_info_similarity`, the attribute-Jaccard between two differing base classes — is
replaced by a table precomputed from Python's `dir()` for the common builtins (identical to the paper's
formula on those), 1.0 for equal names, else 0.

Input: two type maps `gt`/`pred` (variable key → type-node). Output: summed similarity, exact-match
count, total, and missing count — the columns TypyBench's CSV reports.
-/

open Lean PastaLean

namespace TypeInfer.TypeSim

/-- `_get_type_info_similarity` for the common builtins, precomputed via the paper's exact formula on
`dir()`. Symmetric; `0` for any unlisted differing pair. -/
def builtinSim (a b : String) : Option Float :=
  let tbl : List (String × String × Float) := [
    ("bool","int",1.0), ("float","int",0.604), ("bool","float",0.604), ("bytes","str",0.79),
    ("bytearray","bytes",0.765), ("bytearray","str",0.64), ("list","tuple",0.4), ("frozenset","set",0.606),
    ("complex","float",0.5), ("complex","int",0.353), ("bool","complex",0.353), ("dict","list",0.314),
    ("bytearray","list",0.304), ("dict","set",0.25), ("dict","frozenset",0.2), ("str","tuple",0.172),
    ("list","set",0.163), ("bytes","tuple",0.182), ("dict","tuple",0.179), ("bool","frozenset",0.129),
    ("bytes","list",0.13), ("frozenset","list",0.128),
    -- Iteration protocol: a `Generator` IS an `Iterator` IS an `Iterable`; they share `__iter__`/
    -- `__next__`, so a predicted `Iterator` against a ground-truth `Generator`/`Iterable` is close.
    ("Iterator","Generator",0.8), ("Iterator","Iterable",0.7), ("Generator","Iterable",0.6)]
  (tbl.find? (fun (x, y, _) => (x == a && y == b) || (x == b && y == a))).map (·.2.2)

/-- Normalise a type name so `typing` aliases match their builtins (`List`→`list`, `Optional` stays a
marker, `NoneType`→`None`). -/
def normName (s : String) : String :=
  match s with
  | "List" => "list" | "Dict" => "dict" | "Set" => "set" | "FrozenSet" => "frozenset"
  | "Tuple" => "tuple" | "Type" => "type" | "NoneType" => "None"
  -- `PyAny` is our tag for the dynamic top type — the exact role of `typing.Any` — so a nested
  -- `list[PyAny]` scores against a ground-truth `list[Any]` as the same type.
  | "PyAny" => "Any"
  | _ => s

/-- A type node → its base name and argument type-nodes, plus whether it is a union. Handles `Name`,
`Subscript` (container/`Optional`/`Union`, slice a single type or a `Tuple`), `Tuple` literals, and
`BinOp |` unions. -/
partial def analyze (j : Json) : (String × Array Json × Bool) :=
  match jsonNodeType? j with
  | some "Name" => (normName ((j.getObjValAs? String "id").toOption.getD "Any"), #[], false)
  | some "Constant" => ("None", #[], false)  -- `None` literal annotation
  | some "Tuple" => ("tuple", (j.getObjValAs? (Array Json) "elts").toOption.getD #[], false)
  | some "Subscript" =>
      let base := normName (baseNameOf ((j.getObjVal? "value").toOption.getD Json.null))
      let args := sliceArgs ((j.getObjVal? "slice").toOption.getD Json.null)
      if base == "Optional" then ("Union", args.push (Json.mkObj [("node_type", Json.str "Name"), ("id", Json.str "None")]), true)
      else if base == "Union" then (base, args, true)
      else (base, args, false)
  | some "BinOp" =>
      -- `X | Y` union (PEP 604)
      if (j.getObjValAs? String "op").toOption == some "bitor" || (j.getObjValAs? String "op").toOption == some "BitOr" then
        ("Union", #[((j.getObjVal? "left").toOption.getD Json.null), ((j.getObjVal? "right").toOption.getD Json.null)], true)
      else ("Any", #[], false)
  | _ => ("Any", #[], false)
where
  baseNameOf (v : Json) : String :=
    match jsonNodeType? v with
    | some "Name" => (v.getObjValAs? String "id").toOption.getD "Any"
    | some "Attribute" => (v.getObjValAs? String "attr").toOption.getD "Any"  -- typing.List → List
    | _ => "Any"
  sliceArgs (s : Json) : Array Json :=
    match jsonNodeType? s with
    | some "Tuple" => (s.getObjValAs? (Array Json) "elts").toOption.getD #[]
    | some "Index" => sliceArgs ((s.getObjVal? "value").toOption.getD Json.null)
    | _ => if s.isNull then #[] else #[s]

/-- Canonical string of a type node, for the exact-match test (`str(a) == str(b)`). -/
partial def typeStr (j : Json) : String :=
  let (base, args, _) := analyze j
  if args.isEmpty then base
  else base ++ "[" ++ String.intercalate ", " (args.toList.map typeStr) ++ "]"

/-- Optimal assignment value for two small lists under `score`, summed over the best matching, then
divided by the larger length (per `compare_within_level`). Brute-force permutations for ≤ 5, greedy
beyond. `positional` compares index-wise (non-union argument lists). -/
partial def bestMatch (score : Json → Json → Float) (as bs : Array Json) (positional : Bool) : Float :=
  let denom := Float.ofNat (max as.size bs.size)
  if denom == 0 then 0.0 else
  let total :=
    if positional then
      (List.range (min as.size bs.size)).foldl (fun acc i => acc + score as[i]! bs[i]!) 0.0
    else
      -- Hungarian, approximated by greedy max-matching (optimal for the ≤3-element lists that occur).
      greedyAssign score as bs
  total / denom
where
  greedyAssign (score : Json → Json → Float) (as bs : Array Json) : Float := Id.run do
    let mut used : Std.HashSet Nat := {}
    let mut total := 0.0
    for a in as do
      let mut bestJ : Option Nat := none
      let mut bestS := -1.0
      for j in List.range bs.size do
        unless used.contains j do
          let s := score a bs[j]!
          if s > bestS then bestS := s; bestJ := some j
      match bestJ with | some j => used := used.insert j; total := total + bestS | none => pure ()
    return total

/-- `get_type_similarity(a, b)` ∈ [0,1]. -/
partial def sim (a b : Json) : Float :=
  let (an, aargs, aUnion) := analyze a
  let (bn, bargs, bUnion) := analyze b
  if aUnion || bUnion then
    bestMatch sim (if aUnion then aargs else #[a]) (if bUnion then bargs else #[b]) false
  else
    let base := if typeStr a == typeStr b then 1.0 else
      if an == bn then 1.0 else (builtinSim an bn).getD 0.0
    if !aargs.isEmpty && !bargs.isEmpty then (base + bestMatch sim aargs bargs true) / 2.0
    else if !aargs.isEmpty || !bargs.isEmpty then base / 2.0
    else base

/-- Score a repo: for every ground-truth-typed variable, look up the prediction (missing → counts as
0 similarity, present in `missing`), and accumulate summed similarity + exact-match count. -/
def scoreRepo (gt pred : Std.HashMap String Json) : Json := Id.run do
  let mut sumSim := 0.0
  let mut exact := 0
  let mut missing := 0
  let mut total := 0
  for (k, gtType) in gt.toList do
    total := total + 1
    match pred.get? k with
    | none => missing := missing + 1
    | some pType =>
        sumSim := sumSim + sim gtType pType
        if typeStr gtType == typeStr pType then exact := exact + 1
  return Json.mkObj [
    ("total", Json.num (JsonNumber.fromNat total)),
    ("missing", Json.num (JsonNumber.fromNat missing)),
    ("exact", Json.num (JsonNumber.fromNat exact)),
    ("sum_sim", Json.str (toString sumSim))]

end TypeInfer.TypeSim
