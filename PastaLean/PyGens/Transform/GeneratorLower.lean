import Lean

/-!
# Generator lowering (`yield` / `yield from`)

A Python *generator* — a function whose body contains `yield` — is a lazy iterator. PastaLean
models it by **materialising it to a `List α`**: the generator function is rewritten to build and
return a list, so every downstream consumer (`for x in g()`, `list(g())`, `sum(g())`,
`[f(x) for x in g()]`) sees an ordinary `List`, which the `PyIterable` protocol already handles —
no new consumer machinery is needed.

The body rewrite (per generator, in its own scope — a nested function is a separate generator):
* `yield e`        →  `acc.append(e)`   (an ordinary list append; value-semantics reassignment
                                          already threads `acc` through `for`/`while`/`if`)
* `yield from it`  →  `acc.extend(it)`
* `return` / `return v`  →  `return acc` (in a generator, `return` just *stops* iteration; the
                                          accumulated values are the output)
* prepend `acc = []`, append `return acc`.

The accumulator name `__gen'acc` contains a `'`, invalid in Python source, so it can never clash
with a user variable. This pass runs before the other desugar passes, so the synthesised
`append`/`extend` go through the normal pipeline.

Limitation: materialisation is eager, so an *infinite* generator (`while True: yield …`) consumed
lazily does not terminate — the same bound as the unbounded-iterator handling elsewhere.
-/

open Lean

namespace PastaLean

private def ntype? (j : Json) : Option String := (j.getObjValAs? String "node_type").toOption

/-- The accumulator list a generator body appends its yielded values onto. The `'` makes it
unrepresentable in Python source, so it never collides with a user name. -/
private def genAcc : String := "__gen'acc"

private def nameLoad (id : String) : Json :=
  Json.mkObj [("node_type", Json.str "Name"), ("id", Json.str id)]

private def noneConst : Json :=
  Json.mkObj [("node_type", Json.str "Constant"), ("value", Json.null)]

/-- `acc.<method>(arg)` as an `Expr` statement (a `.append`/`.extend` call on the accumulator). -/
private def accMethodStmt (method : String) (arg : Json) : Json :=
  Json.mkObj [("node_type", Json.str "Expr"), ("value", Json.mkObj [
    ("node_type", Json.str "Call"),
    ("func", Json.mkObj [("node_type", Json.str "Attribute"),
                          ("value", nameLoad genAcc), ("attr", Json.str method)]),
    ("args", Json.arr #[arg]),
    ("keywords", Json.mkObj [])])]

private def accInitStmt : Json :=
  Json.mkObj [("node_type", Json.str "Assign"), ("target", nameLoad genAcc),
    ("value", Json.mkObj [("node_type", Json.str "List"), ("elts", Json.arr #[])])]

private def returnAccStmt : Json :=
  Json.mkObj [("node_type", Json.str "Return"), ("value", nameLoad genAcc)]

/-- Does `j` contain a `yield`/`yield from` in its OWN scope (not inside a nested function/lambda,
which is a separate generator)? -/
partial def hasOwnYield (j : Json) : Bool :=
  match ntype? j with
  | some "Yield" | some "YieldFrom" => true
  | some "FunctionDef" | some "AsyncFunctionDef" | some "Lambda" => false
  | _ =>
    match j with
    | .arr elems => elems.any hasOwnYield
    | .obj fields => fields.toList.any (fun (_, v) => hasOwnYield v)
    | _ => false

/-- A constant-truthy test (`while True:` / `while 1:`). -/
private def constTruthy (test : Json) : Bool :=
  ntype? test == some "Constant" &&
    match (test.getObjVal? "value").toOption with
    | some (.bool b) => b
    | some (.num n)  => n != 0
    | _ => false

/-- Any `break`/`return` in this scope (not inside a nested function)? A loop that has one *may*
terminate, so we don't flag it. -/
partial def hasBreakOrReturn (j : Json) : Bool :=
  match ntype? j with
  | some "Break" | some "Return" => true
  | some "FunctionDef" | some "AsyncFunctionDef" | some "Lambda" => false
  | _ =>
    match j with
    | .arr elems => elems.any hasBreakOrReturn
    | .obj fields => fields.toList.any (fun (_, v) => hasBreakOrReturn v)
    | _ => false

/-- A `while True:` (constant-truthy test) with no `break`/`return` in its body cannot terminate,
so materialising it eagerly would loop forever. Conservative: any break/return means "don't flag". -/
partial def hasInfiniteLoop (j : Json) : Bool :=
  match ntype? j with
  | some "FunctionDef" | some "AsyncFunctionDef" | some "Lambda" => false
  | some "While" =>
      let test := (j.getObjVal? "test").toOption.getD Json.null
      let body := (j.getObjVal? "body").toOption.getD (Json.arr #[])
      (constTruthy test && !hasBreakOrReturn body)
        || (match body with | .arr es => es.any hasInfiniteLoop | _ => false)
  | _ =>
    match j with
    | .arr elems => elems.any hasInfiniteLoop
    | .obj fields => fields.toList.any (fun (_, v) => hasInfiniteLoop v)
    | _ => false

mutual
/-- Rewrite `yield`/`yield from`/`return` in one generator statement, recursing into control-flow
bodies but leaving nested functions (separate generators) untouched. -/
partial def rewriteGenStmt (stmt : Json) : Json :=
  match ntype? stmt with
  | some "Expr" =>
      let val := (stmt.getObjVal? "value").toOption.getD Json.null
      match ntype? val with
      | some "Yield" =>
          let yv := (val.getObjVal? "value").toOption.getD Json.null
          accMethodStmt "append" (match yv with | .null => noneConst | _ => yv)
      | some "YieldFrom" =>
          accMethodStmt "extend" ((val.getObjVal? "value").toOption.getD noneConst)
      | _ => stmt
  | some "Return" => returnAccStmt
  | some "FunctionDef" | some "AsyncFunctionDef" | some "ClassDef" | some "Lambda" => stmt
  | some nt =>
      if ["For", "AsyncFor", "While", "If", "With", "AsyncWith", "Try", "Match"].contains nt then
        rewriteGenCompound stmt
      else stmt
  | none => stmt

/-- Recurse `rewriteGenStmt` into every statement-list field of a compound statement (loop/branch
bodies, `try` handlers, `match` cases). -/
partial def rewriteGenCompound (stmt : Json) : Json :=
  let mapBody (j : Json) : Json :=
    ["body", "orelse", "finalbody"].foldl (fun s field =>
      match (s.getObjVal? field).toOption with
      | some (.arr stmts) => s.setObjVal! field (Json.arr (stmts.map rewriteGenStmt))
      | _ => s) j
  let stmt := mapBody stmt
  let stmt := match (stmt.getObjVal? "handlers").toOption with
    | some (.arr handlers) => stmt.setObjVal! "handlers" (Json.arr (handlers.map mapBody))
    | _ => stmt
  match (stmt.getObjVal? "cases").toOption with
    | some (.arr cases) => stmt.setObjVal! "cases" (Json.arr (cases.map mapBody))
    | _ => stmt
end

/-- A generator body becomes `acc = []` … (yields rewritten) … `return acc`. -/
private def lowerGeneratorBody (body : Array Json) : Array Json :=
  (#[accInitStmt] ++ body.map rewriteGenStmt).push returnAccStmt

/-- Walk the whole IR; rewrite each generator `FunctionDef` into a list-building function. Children
are lowered first, so a nested generator is materialised before its enclosing one is examined.
Errors on an *infinite* generator (`while True:` with no exit), which eager materialisation cannot
produce. -/
partial def lowerGenerators (j : Json) : Except String Json := do
  match j with
  | .arr elems => return Json.arr (← elems.mapM lowerGenerators)
  | .obj fields =>
      let j := Json.mkObj (← fields.toList.mapM (fun (k, v) => do pure (k, ← lowerGenerators v)))
      match ntype? j with
      | some "FunctionDef" | some "AsyncFunctionDef" =>
          match (j.getObjVal? "body").toOption with
          | some (.arr body) =>
              if body.any hasOwnYield then
                if body.any hasInfiniteLoop then
                  let name := (j.getObjValAs? String "name").toOption.getD "<anonymous>"
                  throw s!"generator '{name}' has an infinite loop (`while True` with no \
                    `break`/`return`); PastaLean materialises generators to a list eagerly, so an \
                    endless generator cannot be produced. Give the loop a terminating condition."
                else return j.setObjVal! "body" (Json.arr (lowerGeneratorBody body))
              else return j
          | _ => return j
      | _ => return j
  | _ => return j

end PastaLean
