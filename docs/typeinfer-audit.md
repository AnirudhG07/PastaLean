# TypeInfer engine — soundness & completeness audit

A survey of `TypeInfer/` (PyType lattice, Rules `typeOfExpr`, Solve/{Env,Usage,Fixpoint,Stamp,Interproc,SSA})
for places the engine can **assert a wrong type (unsound)**, **give up when it could infer (incomplete)**,
or produce **order-dependent / non-confluent** results. Grounded in the current code.

Legend: 🔴 unsound (can compile wrong code or mis-ascribe → compile error) · 🟡 incomplete (loses precision,
boxes to PyAny) · 🔵 confluence/robustness.

## A. Soundness — asserts a type that need not hold

- 🟢 **`x ** k` → int (`arith`/BinOp).** FIXED (`Rules.lean` BinOp `pow` arm): `a ** -<lit>` with an
  `int` base now types `float` (`2 ** -1 = 0.5`); a non-negative / variable exponent keeps the base's
  numeric type (dominant case — `2**k` for non-neg `k`). A variable exponent that is negative at runtime
  is the residual (rare) unsound corner, and fails loudly (Int-vs-Float mismatch), never silently.
- 🔴 **`x + 1` / `x * 2` on a plain name ⇒ that numeric literal's type** (`Usage.numLit`). `x + 1` types
  `x : int`, but `x` may be `float` (`1.5 + 1`). Pragmatic (dominant case) but not *always* correct —
  a `list[float]` written `[x+1 for x in xs]` would mis-type `int`. Now excludes `pow` (good). Consider
  widening to "numeric" rather than committing to `int`, or gating on no competing float evidence.
- 🟢 **Anchored ordered comparison** (`Usage`, `x < t` where `t`'s type is KNOWN). NOT unsound — this is
  a **sound specialization**. In the translated code `x < (1 : Int)` uses Lean's HOMOGENEOUS `<`, so
  Lean's own constant inference FORCES `x : Int`; the twin is well-typed and correct for `Int` inputs and
  never yields a wrong answer for the type it commits to. The only cost is **completeness**: Python's
  `x < 1` also permits `float`, so a genuinely polymorphic (int+float) function gets a twin specialized to
  one type — a loss of generality that **fails loudly** (a `List ℤ`-vs-float *compile* mismatch), never a
  silent wrong result. The truly unsound version was the OLD *unanchored* `word < ans → int` (neither
  operand typed → a pure guess that mis-typed two `str`s as `int`, wrong for the intended inputs); the
  anchor removed exactly that. (`x + 1 → int` / `x * 2 → int` are the same kind of specialization, though
  `+ₚ` is heterogeneous so the `int` there is a TypeInfer *choice* rather than Lean-forced.)
- 🔴 **`p[i] <op> <literal>` / `p[i].method()` ⇒ `p : list[…]`** (`Usage`). Assumes the subscripted
  container is a LIST. But `p` could be a **dict** (`d[k] < 5` ⇒ wrongly `p:list[int]`, not `dict[_,int]`),
  or `p` a str indexed to a char. Mitigated because a competing dict/`.keys()` signal joins to `any`, and
  str-literals are excluded — but a dict with no other signal is mis-typed. Consider requiring a positive
  list signal, or leaving `unknown` when a dict read of the same name exists.
- 🔴 **`map(f, xs)` ⇒ `list[f's return]` only reads a NAMED `f`** (`Rules.builtinReturn`, added this
  session). Sound for `int`/`str`/user-fn. For a lambda callback it's `list[unknown]` (fine, not unsound),
  but for a builtin like `map(abs, xs)` → `abs` isn't in `constReturnBuiltins` as a *callback* return, so
  `list[unknown]` (incomplete, not unsound).

## B. Incompleteness — could infer soundly but doesn't (→ PyAny / unknown)

- 🟡 **List RETURN mixing is not reconciled** (the `_ret_float` scalar mechanism has no list analogue).
  `Stamp` detects `sawFloat`/`sawOther` only at TOP-LEVEL `.int`/`.float`; a body returning `list[int]`
  in one branch and `list[float]` in another has `returnTypeOf = list[float]` (correct!) but the do-block
  codomain is pinned by the FIRST `return [1]` (List Int) → mismatch. **This is exactly why Tri fails.**
  Fix: ascribe the do-codomain to the joined return type for containers too, and emit numeric list
  literals in return position unascribed so they coerce.
- 🟡 **`str * n` / `n * str` (string repeat) and `s % args` (%-format) → unknown** (`Rules`: `mul` only
  checks `.list` for repeat; `arith`/other ops don't handle str). Should be `str`.
- 🟡 **Backward dataflow through a local — PARTIALLY closed.** A ONE-HOP transparent alias (`q = p`
  copy or `q = p[a:b]` slice, same container type) now back-propagates a decisive use of `q` to the
  param `p` (`paramUsageSeed` alias pass): `ans = text; ans.replace(...)` ⇒ `text : str` (FixSpaces),
  `y = date[6:]; y.isdigit()` ⇒ `date : str` (ValidDate). Only fires when `p` has no direct signal and
  the alias's own type is unambiguous (skips a type-changing local, which is `.any`). The MULTI-hop /
  through-`sorted()` case is still open (ByLength `arr → sorted_list → for x → to_word(x:int)`,
  SortArray116). Also: `f(p[i])` / `f(p[i] + p[j])` — an ELEMENT flowing into an annotated scalar param
  now gives `p : list[T]` (`isPureSubscriptExpr` callee rule; MatchParens `valid(lst[0]+lst[1])`).
- 🟡 **`is_prime(a)` where the helper param is UNannotated.** The callee-annotation rule reads only
  ANNOTATED params. A nested helper whose param type is INFERRED (`a<2`⇒int) doesn't propagate back to
  the argument's source (Skjkasdkd, Intersection). Needs the helper's *inferred* signature.
- 🟡 **`return None` in a boxed-return function emits `Option.none`, not `PyAny.none`** (CompareOne,
  NextSmallest). A codegen gap, not inference — but it makes an otherwise-fine PyAny return fail.
- 🟡 **str-vs-list[str] is genuinely undecidable** without a hint (CountUpper/Encode/Solve161/HexKey/
  RemoveVowels). Correct to leave — noted so it's not mistaken for a bug. (See `bounded-dynamic-typing`.)
- 🟡 **`round`/`map` behaviours don't read a LAMBDA's body return** (only named callbacks / literal
  ndigits). `map(lambda x: x/2, xs)` → `list[unknown]`.

## C. Confluence / robustness

- 🔵 **`join` is now associative** for the `None`/`opt`/`any` cases (absorption `Optional[Any]→Any` was
  added). Good. Container/tuple/fn cases recurse structurally — associative. `a.beq b else any` fallback
  is fine. No known non-confluence remaining, but there is **no proof/test** that `join` is associative
  over the full lattice (only spot cases). A `#guard`/`native_decide` associativity check over a small
  model would harden the "verified lattice" claim.
- 🔵 **Usage vs fixpoint can disagree.** `usageType` (structural, per-name) and `applyStmt`/`inferFunction`
  (env fixpoint) can reach different conclusions; the merge order (`paramUsageSeed` then annotations then
  hints, with `refineElem`) is subtle and only partially tested. The `refineElem` "keep concrete usage
  element over a bare `.any` annotation" is load-bearing and easy to regress.
- 🔵 **SSA loop-carried type mutation is not modelled** (v1). A variable whose type changes *across loop
  iterations* keeps its pre-loop version — could be unsound if such a case arises (rare). Documented.
- 🔵 **`_ret_ty` from globals-free `sigs` can disagree with the env-seeded body** — the `sawAny`
  authoritative-boxing patch handles the known case, but the two sources of the return type (`sigs` vs
  env) are a recurring hazard.

## D. The specific question: are RETURN types concrete, not PyAny?

Mostly yes now:
- Single-type returns → concrete (`_ret_ty`). SSA makes a type-changing return concrete (CountNums → int).
- **Boxed only when returns genuinely disagree** (`.any`) or a branch yields PyAny (`sawAny`) — correct.
- **Two real gaps:** (1) list return-mixing (Tri — `list[int]`⊔`list[float]` not ascribed onto the
  codomain), (2) `return None` in a boxed function (Option.none vs PyAny.none). Both are the return-side
  analogues of param issues and are the clearest next fixes.

## Priority fixes (sound + tractable)
DONE this batch (humaneval 139→144, PALC held): (1) List return-mixing (Tri), (2) `return None →
PyAny.none`, (3) `str*n`/`s%args → str` and `x ** -lit → float`, plus: element-`str` signals
(`p[i].upper()`, `p[i] == " "`) are now AMBIGUOUS `.unknown` not `list[str]` (so a decisive direct
`p.upper()` survives the join — CheckIfLastCharIsALetter), one-hop alias back-prop (FixSpaces, ValidDate),
`f(p[i])` element-callee rule (MatchParens), `List[Any]` → `List PyAny` (Annotation `containerOf` +
codegen FuncDef reader — FilterIntegers), and a latent `learnLit` bug (read `target` singular, not the
chained-only `targets`).

DONE (batches 2+3, humaneval 144→148, PALC 143/143 — Skjkasdkd, ByLength, NumericalLetterGrade, SortArray116):
- **Nested-helper param inference** — `stampFunction` now recurses into nested `def`s (`is_prime(a)` with
  `a<2` ⇒ `a : int`); `paramUsageSeed` enriches the callee map (`fnParams`) with each nested helper's
  INFERRED signature (`nestedParamSig`), so a value passed to an unannotated helper picks up its type.
- **List-producing backward flow** — `sorted_list = sorted(p)[::-1]; for x in sorted_list: is_prime(x:int)`
  ⇒ `p : list[int]` (`listProducingSource` + guarded alias). Only a NON-`str` list element back-propagates
  (`sorted` turns a `str` into `list[str]`, so a str element would reintroduce the str-vs-list ambiguity).
- **`sorted(name, key=cmp_to_key(cmp))`** with annotated `cmp` ⇒ `name : list[cmp's param]` (reverse of
  `stampKeyLambdas`). Handles a bare `key=f` and `cmp_to_key(f)`. Fixed SortArray116.

Remaining (harder):
1. **Intersection** — is_prime `a` PyAny (call-site `r-l` PyAny overrides the body `a<2`⇒int via ParamSig)
   AND intervals need deep backward through `l=interval2[0]`/`min()`.
2. **CheckDictCase** — multi-hop backward through `keys = list(dict.keys())` to `dict[str, PyAny]`.
3. **FindZero/Minpath** — bare-`list`→`List PyAny` numeric cascade (by design; the coefficients/grid are
   numeric but a bare `list` annotation is `List PyAny`).
4. **Scalar float return-mixing under a noncomputable body** (TriangleArea71: `return -1` vs
   `round(x**0.5,2)`) — the ℝ/ℚ/Float dualism; the list fix's scalar analogue, gated by noncomputability.
5. **str-vs-list[str]** (CountUpper/Encode/HexKey/RemoveVowels/SortedListSum/Solve161/StrongestExtension/
   ReverseDelete/DoAlgebra/DecodeCyclic) — genuinely undecidable without a hint (see `bounded-dynamic-typing`).
