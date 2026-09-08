import TypeInfer
import PastaLean.PyGens.Core.JsonBasic

/-!
# Repo-level type inference (all module/import logic in Lean)

The Python side is a dumb pipe: it parses each `.py` in the repo to its own IR (`node_visitor`, an
AST→JSON transform, no inference) and hands us the whole set keyed by dotted module name. EVERYTHING
about cross-file inference — resolving imports, composing the modules, and running the fixpoint — is
done here.

We resolve imports purely against the provided module dictionary (no filesystem), then COMPOSE the
repo into one program whose top-level symbols are module-qualified (`helper.f` → `m_helper_f`), with
each module's references rewritten to those qualified names. The composed program is fed to the
existing single-module `inferModule` fixpoint ONCE. Because `join` is a monotone, commutative,
associative least-upper-bound (see `Lattice`/`Theorems`), this one global fixpoint is order- and
grouping-independent, so import cycles need no special handling: a back-edge is just another join into
the same signature table. Results are split back out per module for the driver to read.

This ports `driver.resolve_local_imports` off the Python side; the inference core is unchanged.
-/

open Lean PastaLean

namespace TypeInfer.Repo

/-- A name a module binds through an import: either a module alias (`import pkg.mod as m`) or a direct
symbol (`from helper import f` → the qualified symbol `f` resolves to in the target module). -/
inductive Bind where
  | modAlias (dotted : String)
  | symbol   (qualified : String)
  deriving Inhabited

/-- The composed top-level name for a module member: `helper.f` → `m_helper_f`. `.` becomes `_`, so a
mangled name never collides with a user's (no Python name contains the leading `m_<dotted>_` shape). -/
def mangle (dotted name : String) : String :=
  "m_" ++ dotted.replace "." "_" ++ "_" ++ name

/-- First dotted segment: `pkg.mod` → `pkg`. -/
def firstSeg (s : String) : String := (s.splitOn ".").headD s

/-- Enclosing package of a dotted module: `a.b.c` → `a.b`, `a` → `""`. -/
def pkgOf (dotted : String) : String :=
  let segs := dotted.splitOn "."
  if segs.length ≤ 1 then "" else ".".intercalate segs.dropLast

/-- The original `(dotted, name)` a mangled symbol came from, longest-module-prefix wins. -/
def unmangle? (s : String) (known : List String) : Option (String × String) := Id.run do
  unless s.startsWith "m_" do return none
  let core := (s.drop 2).toString
  let mut best : Option (String × String) := none
  for d in known do
    let pre := d.replace "." "_" ++ "_"
    if core.startsWith pre then
      let better := match best with | some (bd, _) => decide (d.length > bd.length) | none => true
      if better then best := some (d, (core.drop pre.length).toString)
  return best

/-- Top-level `FunctionDef`/`ClassDef` names declared by a module IR. -/
def topNames (ir : Json) : Array String :=
  match ir.getObjValAs? (Array Json) "body" with
  | .ok body => body.filterMap fun s =>
      match jsonNodeType? s with
      | some "FunctionDef" | some "ClassDef" => (s.getObjValAs? String "name").toOption
      | _ => none
  | _ => #[]

/-- Parse a module's `Import`/`ImportFrom` nodes into a bind map, resolving each against the modules
actually present (`members` keys). Foreign imports (numpy, …) simply don't resolve and are ignored. -/
def bindsOf (ir : Json) (dotted : String)
    (members : Std.HashMap String (Std.HashMap String String)) : Std.HashMap String Bind := Id.run do
  let pkg := pkgOf dotted
  let mut binds : Std.HashMap String Bind := {}
  let body := (ir.getObjValAs? (Array Json) "body").toOption.getD #[]
  for node in body do
    match jsonNodeType? node with
    | some "Import" =>
        for a in (node.getObjValAs? (Array Json) "names").toOption.getD #[] do
          let name := (a.getObjValAs? String "name").toOption.getD ""
          if members.contains name then
            let asname := (a.getObjValAs? String "asname").toOption
            binds := binds.insert (asname.getD (firstSeg name)) (.modAlias (if asname.isSome then name else firstSeg name))
    | some "ImportFrom" =>
        let level := (node.getObjValAs? Nat "level").toOption.getD 0
        let modRaw := (node.getObjValAs? String "module").toOption.getD ""
        let mod := if level > 0 && pkg != "" then (if modRaw == "" then pkg else pkg ++ "." ++ modRaw) else modRaw
        for a in (node.getObjValAs? (Array Json) "names").toOption.getD #[] do
          let name := (a.getObjValAs? String "name").toOption.getD ""
          let key := (a.getObjValAs? String "asname").toOption.getD name
          match (members.get? mod).bind (·.get? name) with
          | some q => binds := binds.insert key (.symbol q)
          | none =>
              let sub := if mod == "" then name else mod ++ "." ++ name
              if members.contains sub then binds := binds.insert key (.modAlias sub)
    | _ => pure ()
  return binds

/-- Walk an attribute chain `a.b.c` to head-first segments `[a, b, c]`, or `none`. -/
partial def attrChain (j : Json) : Option (Array String) :=
  let rec go (j : Json) (acc : Array String) : Option (Array String) :=
    match jsonNodeType? j with
    | some "Attribute" =>
        match (j.getObjValAs? String "attr").toOption, j.getObjVal? "value" with
        | some attr, .ok v => go v (acc.push attr)
        | _, _ => none
    | some "Name" => ((j.getObjValAs? String "id").toOption).map (fun id => (acc.push id).reverse)
    | _ => none
  go j #[]

mutual
/-- Rewrite references in one IR subtree: a `Name` bound to a symbol becomes that qualified symbol or
its local-def mangled name; a `mod.attr` (mod a module alias) becomes the target's mangled member. -/
partial def rewrite (binds : Std.HashMap String Bind) (localMangle : Std.HashMap String String)
    (members : Std.HashMap String (Std.HashMap String String)) (j : Json) : Json :=
  match jsonNodeType? j with
  | some "Attribute" =>
      match attrChain j with
      | some chain =>
          if chain.size ≥ 2 then
            match binds.get? chain[0]! with
            | some (.modAlias d0) =>
                let modName := (chain.extract 1 (chain.size - 1)).foldl (fun m s => m ++ "." ++ s) d0
                match (members.get? modName).bind (·.get? chain[chain.size-1]!) with
                | some q => Json.mkObj [("node_type", Json.str "Name"), ("id", Json.str q)]
                | none => rewriteKids binds localMangle members j
            | _ => rewriteKids binds localMangle members j
          else rewriteKids binds localMangle members j
      | none => rewriteKids binds localMangle members j
  | some "Name" =>
      match (j.getObjValAs? String "id").toOption with
      | some id =>
          match binds.get? id with
          | some (.symbol q) => j.setObjVal! "id" (Json.str q)
          | _ => match localMangle.get? id with
                 | some m => j.setObjVal! "id" (Json.str m)
                 | none => j
      | none => j
  | _ => rewriteKids binds localMangle members j

/-- Structural recursion of `rewrite` into every child value. -/
partial def rewriteKids (binds : Std.HashMap String Bind) (localMangle : Std.HashMap String String)
    (members : Std.HashMap String (Std.HashMap String String)) (j : Json) : Json :=
  match j with
  | .arr xs => Json.arr (xs.map (rewrite binds localMangle members))
  | .obj fields => Json.mkObj (fields.toList.map (fun (k, v) => (k, rewrite binds localMangle members v)))
  | _ => j
end

/-- Rewrite one module against the repo: rename its top defs/classes to mangled (module-qualified)
names, rewrite references (imports + intra-module self-calls) to those names, drop import nodes. -/
def rewriteModule (members : Std.HashMap String (Std.HashMap String String))
    (d : String) (ir : Json) : Json := Id.run do
  let binds := bindsOf ir d members
  let localMangle := members.getD d {}
  let mut body : Array Json := #[]
  for stmt in (ir.getObjValAs? (Array Json) "body").toOption.getD #[] do
    match jsonNodeType? stmt with
    | some "Import" | some "ImportFrom" => pure ()
    | some "FunctionDef" | some "ClassDef" =>
        let name := (stmt.getObjValAs? String "name").toOption.getD ""
        body := body.push ((rewrite binds localMangle members stmt).setObjVal! "name" (Json.str (mangle d name)))
    | _ => body := body.push (rewrite binds localMangle members stmt)
  return Json.mkObj [("node_type", Json.str "Module"), ("body", Json.arr body)]

/-- Restore original (un-mangled) names throughout a stamped module — both a def's `name` field AND
every `Name` node's `id`. The latter matters because an inferred type that refers to a class carries
that class's (mangled) name (`.cls "m_pkg_mod_Installer"`); un-mangling it back to `Installer` is what
the def-name-only pass missed, leaking mangled identifiers into inferred type annotations. -/
partial def restoreNames (known : List String) (j : Json) : Json :=
  match j with
  | .arr xs => Json.arr (xs.map (restoreNames known))
  | .obj _ =>
      let j := match (j.getObjValAs? String "name").toOption.bind (fun n => unmangle? n known) with
        | some (_, orig) => j.setObjVal! "name" (Json.str orig)
        | none => j
      let j := match (j.getObjValAs? String "node_type").toOption, (j.getObjValAs? String "id").toOption with
        | some "Name", some id => match unmangle? id known with
            | some (_, orig) => j.setObjVal! "id" (Json.str orig)
            | none => j
        | _, _ => j
      match j with
      | .obj fields => Json.mkObj (fields.toList.map (fun (k, v) => (k, restoreNames known v)))
      | _ => j
  | _ => j

/-- Merge one module's signatures into the global table, joining on collision. Mangled top-level keys
(`m_pkg_mod_f`) are globally unique, so a collision is only the shared class-method/field convention;
`join` (the lattice LUB) keeps the accumulation monotone, which is what makes the cross-module fixpoint
below order-independent and cycle-safe. -/
def mergeSigs (g m : TypeInfer.Sigs) : TypeInfer.Sigs :=
  m.fold (fun acc k v => acc.insert k (match acc.get? k with
    | some old => TypeInfer.PyType.join old v | none => v)) g

/-- Element-wise join of two parameter-signature tables (pad the shorter arity with `unknown`).
`collectSigs` applies the seed FILL-ONLY (only `unknown` annotation slots), so a widened union here
never overwrites a module's own concrete annotation. -/
def mergeParams (g m : TypeInfer.ParamSigs) : TypeInfer.ParamSigs :=
  m.fold (fun acc k v => acc.insert k (match acc.get? k with
    | some old =>
        let n := max old.size v.size
        (Array.range n).map (fun i =>
          TypeInfer.PyType.join (old[i]?.getD .unknown) (v[i]?.getD .unknown))
    | none => v)) g

/-- Repo-level inference with a SHARED GLOBAL signature table. Each module is rewritten to qualified
(mangled) names so top-level symbols live in one flat namespace, then:

  * Pass 1 (the cross-module fixpoint, 2 iterations): iteration 1 runs every module's `collectSigs`
    from an empty seed and merges (joins) the results into the global table; iteration 2 re-runs only
    the IMPORTER modules against that table and merges them in. Because `join` is a monotone LUB (see
    `Lattice`/`Theorems`), the table only grows and converges regardless of order, so a `helper.f()`
    return learned in iteration 1 reaches every importer in iteration 2, and import cycles are just
    back-edges. Recomputing only importers is EXACT — a module that references no other module's
    symbols has a seed-independent `collectSigs`, so its 2nd result equals its 1st — and cheap: it
    trades the memory of keeping iteration 1's per-module results for skipping ~half the fixpoints.
    (Two iterations suffice; a 3rd was measured worth <0.001 TypeSim — depth-2 chains are the tail.)
  * Pass 2: stamp each module's bodies with the converged tables — reusing the local `(sigs, params)`
    that pass 1's last `collectSigs` already produced (2 `collectSigs` per module, not 3), so a
    cross-module call site (`x = helper.f()`) reads the callee's real return type and an
    otherwise-unknown parameter is filled from its call sites, then `restoreNames`.

Both passes are MULTICORE: modules are independent given the shared read-only seed, so each pass fans
one task per module onto Lean's task scheduler (a pool of native threads across all physical cores,
`LEAN_NUM_THREADS`), the same shared-memory model pyrefly/ty use — trading the memory of N concurrent
per-module working sets (cheap) for a near-linear speedup. RETURN signatures cross module boundaries
freely; PARAMETERS cross FILL-ONLY — `collectSigs` fills only a parameter's unannotated (`unknown`)
slots from the seed and never widens a concrete annotation, because a plain global join over every
module's call sites widens a param into a dropped union (that variant measured net-negative:
0.211→0.193 TypeSim). Cost is O(iters × #modules × module-size), spread across cores: still per-module
fixpoints, never one giant composed program, so it scales. -/
def inferRepo (modules : Std.HashMap String Json) : Std.HashMap String Json := Id.run do
  let known := modules.toList.map (·.1)
  let members : Std.HashMap String (Std.HashMap String String) :=
    modules.toList.foldl (fun m (d, ir) => m.insert d ((topNames ir).foldl (fun mm n => mm.insert n (mangle d n)) {})) {}
  -- Rewrite + SSA every module once; the mangled IR is reused across both passes. Sort LARGEST FIRST
  -- (by top-level statement count, a cheap cost proxy) so the task scheduler starts the long-pole
  -- modules at t=0 — the LPT heuristic that shrinks makespan when a few big modules dominate a repo.
  let rewritten : Array (String × Json) :=
    let arr := (modules.toList.map (fun (d, ir) =>
      (d, TypeInfer.ssaModule (rewriteModule members d ir)))).toArray
    arr.qsort (fun a b =>
      ((a.2.getObjValAs? (Array Json) "body").toOption.getD #[]).size >
      ((b.2.getObjValAs? (Array Json) "body").toOption.getD #[]).size)
  -- Pass 1: cross-module signature fixpoint into one global table. Returns (and class field/type
  -- signatures) accumulate by join; params accumulate by join here too but are APPLIED fill-only in
  -- `collectSigs` (a widened param union only fills unannotated slots, never overwrites a concrete
  -- annotation) — a plain global param seed measured net-negative (0.211→0.193 TypeSim).
  -- Modules are inferred independently given the shared read-only seed, so both passes fan out across
  -- the task-scheduler thread pool (one task per module, `LEAN_NUM_THREADS` threads in one process).
  -- The extra memory of N concurrent per-module working sets is cheap (each is a few MB) and buys a
  -- near-linear speedup on many-module repos — where a single sequential thread was the bottleneck.
  let parMap {β : Type} (f : String × Json → β) : Array β :=
    (rewritten.map (fun m => Task.spawn (fun _ => f m))).map (·.get)
  -- A module IMPORTS cross-module iff `bindsOf` (on the ORIGINAL ir, before imports are dropped)
  -- resolves any name to another repo module. A non-importer references no other module's symbols, so
  -- its `collectSigs` is independent of the global seed — its 2nd-iteration result is bit-identical to
  -- its 1st. So iteration 2 only RECOMPUTES importers and reuses iteration 1's result for the rest:
  -- the cross-module return that iter 1 discovered still reaches every importer, at a fraction of the
  -- cost (the memory of keeping iter-1's per-module results traded for skipping ~half the fixpoints).
  let importers : Std.HashSet String := modules.toList.foldl (fun s (d, ir) =>
    if (bindsOf ir d members).isEmpty then s else s.insert d) {}
  -- Iteration 1: collect every module from an empty seed, merge into the global table.
  let results0 := parMap (fun (_, ir) => TypeInfer.collectSigs ir {} {})
  let mut gSigs : TypeInfer.Sigs := {}
  let mut gParams : TypeInfer.ParamSigs := {}
  for (s, p) in results0 do
    gSigs := mergeSigs gSigs s
    gParams := mergeParams gParams p
  -- Iteration 2: recompute ONLY importers against the converged global seed; reuse iter-1 otherwise.
  let gS := gSigs; let gP := gParams
  let tasks : Array (Option (Task (TypeInfer.Sigs × TypeInfer.ParamSigs))) :=
    rewritten.map (fun (d, ir) =>
      if importers.contains d then some (Task.spawn (fun _ => TypeInfer.collectSigs ir gS gP)) else none)
  let results1 : Array (TypeInfer.Sigs × TypeInfer.ParamSigs) :=
    tasks.mapIdx (fun i t => match t with | some tk => tk.get | none => results0[i]!)
  let mut lastLocal : Array (TypeInfer.Sigs × TypeInfer.ParamSigs) := results1
  for i in [0:rewritten.size] do
    if importers.contains rewritten[i]!.1 then
      gSigs := mergeSigs gSigs results1[i]!.1
      gParams := mergeParams gParams results1[i]!.2
  -- Pass 2: stamp each module's bodies. We REUSE each module's own local `(sigs, params)` from pass 1's
  -- last `collectSigs` (which already folds in the cross-module seed) rather than re-running the
  -- fixpoint inside `inferModule` — 2 `collectSigs` per module instead of 3. Returns flow freely;
  -- params flow FILL-ONLY (only unannotated slots get filled, never widening a concrete annotation).
  -- Stamp with the FINAL merged return table `gSigs` (mangled keys are globally unique, so it is a
  -- superset of the module's own returns and adds cross-module ones) but the module's OWN fill-only
  -- `params` (never the join-widened global params, which would reintroduce dropped unions).
  let stamped := (Array.range rewritten.size).map (fun i =>
    Task.spawn (fun _ =>
      let (d, ir) := rewritten[i]!
      let params := lastLocal[i]!.2
      (d, restoreNames known (TypeInfer.stampModuleWith ir gSigs params))))
  return (stamped.map (·.get)).foldl (fun m (d, st) => m.insert d st) {}

end TypeInfer.Repo
