import TypeInfer.Solve.Env

/-!
## Minimal SSA renaming on TYPE MUTATIONS

Standard SSA versions a variable at every assignment; we version ONLY when a reassignment changes the
variable's TYPE (e.g. `l = list(str(x))` then `l = list(map(int, l))` — str-list → int-list). Same-type
reassignments keep the name (so `let mut` counters/accumulators are untouched). The original name has no
`'`; each new version is `x'v1`, `x'v2`, … (the `'` makes them Python-invalid, so they never clash).

This lets a variable that holds different types at different program points be typed CONCRETELY (each
version a distinct binder) instead of boxed to `PyAny`. At a branch JOIN where the versions agree, the
merge stays concrete; where they genuinely conflict, the merged version's type is the join (→ `PyAny`,
the Option-A fallback). Contracts (`Requires`/`Ensures`/`Invariant`/`Decreases`) are ordinary
expressions, so use-rewriting maps them to the most-fresh version live at their position.

Runs after desugaring, before the stamping/codegen passes, which then type each version cleanly.
-/

namespace TypeInfer
open Lean

/-- A reassignment is a TYPE MUTATION (needs a new SSA version) when the new type genuinely differs
from the old: not equal, neither `unknown` (a refinement, not a change), and not a numeric-tower
widening (`int`/`nat`/`bool`/`float`/`rat` interconvert). Container element changes DO count
(`list[str]` → `list[int]`). -/
partial def isTypeMutation : PyType → PyType → Bool
  | old, new =>
    if old == new then false
    else if old == .unknown || new == .unknown || old == .any || new == .any then false
    else
      let numeric : PyType → Bool
        | .int | .bool | .float => true | _ => false
      if numeric old && numeric new then false
      else match old, new with
        | .list a, .list b => isTypeMutation a b
        | .set a, .set b => isTypeMutation a b
        -- `x = None` then `x = v` (a nullable accumulator, `min_pair = None; min_pair = (l,r)`) is
        -- Optional-WIDENING, not a type change — `x : Option τ`, handled by the nullable codegen. SSA
        -- must NOT version it: inside a loop the loop-carried phi is unmodelled, so versioning silently
        -- drops the update (the accumulator stays `none`). Leaving it un-versioned keeps `x` Optional.
        | .none, _ | _, .none => false
        | .opt _, _ | _, .opt _ => false
        | _, _ => true

/-- Rewrite every `Name` use per `ren` (origName → curName). Skips nested `FunctionDef`s (own scope). -/
partial def ssaRewriteUses (ren : Std.HashMap String String) (j : Json) : Json :=
  if nodeTypeOf j == some "FunctionDef" then j
  else match j with
    | .obj _ =>
        let j := if nodeTypeOf j == some "Name" then
            match (nameId? j).bind ren.get? with
            | some cn => j.setObjVal! "id" (Json.str cn)
            | none => j
          else j
        match j with
        | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, ssaRewriteUses ren v)))
        | _ => j
    | .arr xs => Json.arr (xs.map (ssaRewriteUses ren))
    | _ => j

private def nameNode (id : String) : Json :=
  Json.mkObj [("node_type", .str "Name"), ("id", .str id)]

private def phiAssign (target value : String) : Json :=
  Json.mkObj [("node_type", .str "Assign"), ("target", nameNode target),
              ("value", nameNode value)]

/-- The single `Name` target of an `Assign` (`x = …`), if any (`targets`[0] or `target`). -/
private def assignName? (s : Json) : Option String :=
  match (getField s "targets").bind (fun t => (t.getArr?).toOption) with
  | some ts => ts[0]?.bind nameId?
  | none => (getField s "target").bind nameId?

private def setAssignTarget (s : Json) (name : String) : Json :=
  if (getField s "targets").isSome then s.setObjVal! "targets" (Json.arr #[nameNode name])
  else s.setObjVal! "target" (nameNode name)

/-- origName → curName / origName → type, from the table. -/
private def renOf (tbl : Std.HashMap String (String × PyType)) : Std.HashMap String String :=
  tbl.fold (fun m k (cn, _) => m.insert k cn) {}
private def envOf (tbl : Std.HashMap String (String × PyType)) : Env :=
  tbl.fold (fun m k (_, t) => m.insert k t) {}

/-- SSA-rename a statement list. Threads the fresh counter `n` and the table `origName → (curName,
type)`. Returns the rewritten statements, the table at the end, and the counter. -/
partial def ssaStmts (sigs : Sigs) (n0 : Nat) (tbl0 : Std.HashMap String (String × PyType))
    (stmts : Array Json) : Array Json × Std.HashMap String (String × PyType) × Nat := Id.run do
  let mut n := n0
  let mut tbl := tbl0
  let mut out : Array Json := #[]
  for s in stmts do
    let ren := renOf tbl
    match nodeTypeOf s with
    | some "Assign" =>
        match assignName? s with
        | some x =>
            let val := getField s "value"
            let t := val.elim .unknown (typeOfExpr sigs (envOf tbl))
            -- rewrite RHS uses with the CURRENT names (self-reference `l = f(l)` reads the old `l`)
            let s := match val with | some v => s.setObjVal! "value" (ssaRewriteUses ren v) | none => s
            match tbl.get? x with
            | none => tbl := tbl.insert x (x, t); out := out.push s
            | some (cn, t0) =>
                if isTypeMutation t0 t then
                  n := n + 1
                  let nm := s!"{x}'v{n}"
                  tbl := tbl.insert x (nm, t)
                  out := out.push (setAssignTarget s nm)
                else
                  tbl := tbl.insert x (cn, PyType.join t0 t)
                  out := out.push (if cn == x then s else setAssignTarget s cn)
        | none => out := out.push (ssaRewriteUses ren s)
    | some "If" =>
        let s := match getField s "test" with | some c => s.setObjVal! "test" (ssaRewriteUses ren c) | none => s
        let body := (s.getObjValAs? (Array Json) "body").toOption.getD #[]
        let orelse := (s.getObjValAs? (Array Json) "orelse").toOption.getD #[]
        let (bodyA, tblA, nA) := ssaStmts sigs n tbl body
        let (bodyB, tblB, nB) := ssaStmts sigs nA tbl orelse
        n := nB
        let mut a := bodyA
        let mut b := bodyB
        let mut phis : Array String := #[]     -- phi targets to add to `if_assigned_names` (hoisting)
        -- merge: reconcile every variable whose version/type diverged across the branches
        let keys := (tblA.fold (fun (acc : Std.HashSet String) k _ => acc.insert k) {})
        let keys := tblB.fold (fun acc k _ => acc.insert k) keys
        for x in keys do
          let va := (tblA.get? x).orElse (fun _ => tbl.get? x)
          let vb := (tblB.get? x).orElse (fun _ => tbl.get? x)
          match va, vb with
          | some (na, ta), some (nb, tb) =>
              if na == nb && ta == tb then tbl := tbl.insert x (na, ta)
              else
                n := n + 1
                let nm := s!"{x}'v{n}"
                a := a.push (phiAssign nm na)
                b := b.push (phiAssign nm nb)
                phis := phis.push nm
                tbl := tbl.insert x (nm, PyType.join ta tb)
          | some v, none | none, some v => tbl := tbl.insert x v
          | none, none => pure ()
        -- A phi target is assigned in BOTH branches and read after the `if`, so it must be pre-declared
        -- (`let mut … := default`) before the `if`. That list is `if_assigned_names` (stamped by the
        -- Python pre-pass, before SSA ran) — append the new phi names so the hoist covers them.
        let prevNames := (s.getObjValAs? (Array String) "if_assigned_names").toOption.getD #[]
        let s := s.setObjVal! "if_assigned_names" (Json.arr ((prevNames ++ phis).map Json.str))
        out := out.push ((s.setObjVal! "body" (Json.arr a)).setObjVal! "orelse" (Json.arr b))
    | some "While" | some "For" =>
        -- Conservative for v1: rewrite test/iter uses, SSA the body, but a var whose type MUTATES
        -- inside the loop keeps its pre-loop version afterwards (loop-carried header-phi not modelled).
        let s := match getField s "test" with | some c => s.setObjVal! "test" (ssaRewriteUses ren c) | none => s
        let s := match getField s "iter" with | some c => s.setObjVal! "iter" (ssaRewriteUses ren c) | none => s
        let s := match getField s "target" with | some c => s.setObjVal! "target" (ssaRewriteUses ren c) | none => s
        let body := (s.getObjValAs? (Array Json) "body").toOption.getD #[]
        let (body', _, n') := ssaStmts sigs n tbl body
        n := n'
        out := out.push (s.setObjVal! "body" (Json.arr body'))
    | _ =>
        out := out.push (ssaRewriteUses ren s)
  return (out, tbl, n)

/-- Seed the table with a function's parameters (kept at their own names) and SSA-rename its body,
recursing into nested defs (each its own scope). -/
partial def ssaFunction (sigs : Sigs) (fn : Json) : Json := Id.run do
  let body := (fn.getObjValAs? (Array Json) "body").toOption.getD #[]
  let mut tbl : Std.HashMap String (String × PyType) := {}
  match (fn.getObjVal? "args").toOption.bind (fun a => (a.getObjValAs? (Array Json) "args").toOption) with
  | some argsArr => for a in argsArr do
      if let some nm := (a.getObjValAs? String "arg").toOption then
        let t := match getField a "annotation" with
          | some ann => if ann.isNull then PyType.unknown else ofAnnotation ann
          | none => .unknown
        tbl := tbl.insert nm (nm, t)
  | none => pure ()
  -- recurse into nested defs first (separate scopes)
  let body := body.map (fun s => if nodeTypeOf s == some "FunctionDef" then ssaFunction sigs s else s)
  let (body', _, _) := ssaStmts sigs 0 tbl body
  fn.setObjVal! "body" (Json.arr body')

/-- Apply SSA renaming to every function in a module (or a bare top-level body). -/
partial def ssaModule (json : Json) : Json :=
  match json with
  | .obj _ =>
      if nodeTypeOf json == some "FunctionDef" then ssaFunction {} json
      else match json with
        | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, ssaModule v)))
        | _ => json
  | .arr xs => Json.arr (xs.map ssaModule)
  | _ => json

end TypeInfer
