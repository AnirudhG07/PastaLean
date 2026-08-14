import TypeInfer.Solve.Interproc

/-!
The type-inference engine, split by concern under `TypeInfer/Solve/`:
* `Env`       — per-statement environment updates (`applyStmt`, `compBindings`, AST helpers).
* `Usage`     — usage-based parameter typing (`usageType` and its predicates).
* `Fixpoint`  — the per-function inference fixpoint (`inferFunction`, `returnTypeOf`).
* `Stamp`     — writing inferred types back onto the IR as `_ty` (all `stamp*`/`mark*`, array-seq).
* `Interproc` — interprocedural flow + the module entry point (`collectSigs`, `inferModule`).

Re-exports the whole engine, so `import TypeInfer.Solve` is unchanged for callers.
-/
