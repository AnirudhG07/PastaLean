# Contract QA — a generate → verify → repair pipeline

`docs/contract-prompt-system.md` tells a model how to write contracts. This document is about what
happens **after** it does: how a candidate `solution_contracts.py` is proved fit to ship, and what
happens when it is not.

There is **one** command — `pastabench.py contracts` — and it is the whole loop. Writing contracts
and checking them are not separable steps: a candidate that fails a gate is not a contract file, it
is a draft, and the pipeline's job is to not confuse the two.

Implementation: `src/transpile/contract_qa/`. CLI:
`python3 PastaBench/pastabench.py contracts --track humaneval`, or
`python -m pastalean.transpile.contract_qa <dir>`.

## Why

The previous generator was one-shot: prompt the model, check that the output parses, defines the
same functions, and contains at least one `Ensures` mentioning `Result()`, then write the file.
Running a runtime validator over the 164-unit HumanEval track found the shipped contracts carrying,
among others:

- postconditions that are simply **false** (unprovable, and the benchmark then asserts an untruth);
- contracts built from `Forall` / `Implies` / `Old`, which have **no Lean mapping** — `Implies`
  returns `True` unconditionally, so the spec was silently **vacuous**; `Old` is not defined at all
  and raised `NameError` on every call;
- `Ensures` on a nested helper (attributed to the enclosing entry point, read in the wrong scope);
- `Ensures` naming a local bound **below** it — a contract argument is evaluated eagerly, so the
  function raised `UnboundLocalError` on *every* input;
- postconditions naming a **loop-mutated** variable: true in Python (which captures the entry
  value), unsatisfiable in Lean (which reads the final value);
- a contracted file whose **behaviour differed** from the reference `solution.py`;
- specifications a **wrong answer** satisfies.

Only the last of those needs judgement. Every other item is decidable by a parser or a test run, so
none of them should ever have reached a model's opinion, let alone a proof attempt.

## The gate ladder

Cheapest and most decisive first. A unit that fails a gate does not proceed to the next one, and
**a file that fails any hard gate is never written**.

### 1. Static (`static_gates.py`) — no execution

| check | what it rejects |
|---|---|
| `syntax` | does not parse |
| `forbidden` | `Forall`/`ForAll`/`Implies`/`Old`/`Refute`/`Exsures`/`Unfold`/`Reveal`/`isNaN` — no Lean mapping; half of them return `True` (vacuous), the rest raise |
| `import` | contract markers used without `from contracts import *` |
| `scope` | a contract reads a name that is not yet bound at that point (eager evaluation → `UnboundLocalError`), or is not bound anywhere |
| `nested_ensures` | `Ensures` inside an inner `def` |
| `loop_mutated` | a postcondition names a variable some loop reassigns (Python reads the entry value, Lean the final one) |
| `mid_function` | `Ensures` / `Result()`-bearing `Assert` with a loop both before **and** after it — mirrors `hasMidFunctionPostcondition` in `PastaLean/PyVerify/Contracts.lean` |
| `invariant_placement` | `Invariant` outside a loop (error), or not in the leading group of the loop body (warning) |
| `vacuous` | zero *substantive* `Ensures` — nothing non-trivial is claimed about the return value |
| `result_misuse` | `Result()` inside a `Requires`/`Invariant`/… |
| `entry` / `dropped_defs` | the unit's entry point is gone, or a definition the reference had was dropped |
| `lowerability` (warn) | 3-arg `pow`, 2-arg `int(s, base)`, `math.pow`, `random.*`/`hashlib.*`/…, `is`-identity (lowers to structural `==`, so it asserts nothing), chained comparisons in a contract, and multi-clause comprehensions inside `all`/`any` (which fall back to an inert `Bool` fold instead of a real quantifier) |

Scope analysis is a real binding walk, not a `grep`: comprehension targets, lambda parameters,
`with`/`except`/`for` targets and walrus bindings all bind, and module-level globals are resolved at
call time (so a helper defined *below* the function that names it is fine, while a *local* bound
below is not).

### 2. Dynamic (`dynamic.py`) — one subprocess per unit

Three things at once, over the unit's recorded `tests.json` inputs:

1. **Behaviour identity.** The reference `solution.py` is run on the same parsed inputs and its
   return values become the oracle. The contracted twin must return exactly those. Contracts are
   runtime no-ops; any drift means the theorem would be about a different program.
2. **Contract truth.** `Requires` / `Assume` / `Assert` / `Invariant` / `Decreases` stay
   runtime-asserted, but raise a `ContractViolation` naming the marker, so a later kill can be
   attributed.
3. **Postcondition truth.** This is the one the shim cannot do for itself. An `Ensures` argument is
   evaluated *eagerly, at the top of the body*, where the return value does not exist — the real
   shim's `Result()` is `None`, so `Result() % 2` would crash. So each postcondition is handled
   twice: an inert absorbing stand-in absorbs every operation *during* the call (the program runs
   unchanged, and an unbound name still raises, which is exactly what we want to see), and then the
   clause is re-evaluated *after* the call with `Result()` bound to the value actually returned.
   Only the second evaluation decides anything.

Snapshot locals (`n_0 = n`) are not in scope after the call, so the return frame's locals are
captured with a tracer and made available to the re-evaluation — but only when a postcondition
actually names something that is neither a parameter nor a global, since tracing costs ~10× a call.
Entry arguments override captured locals, mirroring how Lean's snapshot substitution resolves a
parameter the body mutates.

The subprocess boundary is not paranoia: mutants loop forever and allocate without bound. The child
carries an address-space rlimit, a per-call `setitimer`, and a parent-side wall clock.

### 3. Mutation (`mutation.py`) — is the specification worth anything?

A contract can be well-formed, behaviour-preserving, and true on all fifty recorded inputs, and
still say nothing. Every gate above passes such a spec. So the question is asked the other way
round: **which wrong programs does this specification reject?**

This is classical mutation testing (DeMillo/Lipton/Sayward 1978; as automated by
[`mutmut`](https://github.com/boxed/mutmut) and
[`cosmic-ray`](https://github.com/sixty-north/cosmic-ray)) with the roles inverted — the *mutants*
play the part of the test suite, and the *contract* is the artifact being scored. It is the same
move Dafny/Verus users make by hand when they ask "would a broken implementation still verify?",
and it is the automatable half of the "determined, not merely constrained" rule in
`contract-prompt-system.md`.

Single-point mutants of the implementation (never of a contract argument — that would be mutating
the specification):

`compare` (`<`↔`<=`, `==`↔`!=`, `<`↔`>`, `in`↔`not in`) · `arith` (`+`↔`-`, `*`→`+`, `//`→`*`,
`%`→`//`, `**`→`*`) · `swap_operands` (for non-commutative ops) · `boolop` (`and`↔`or`) ·
`drop_not` · `const` (integer ±1, boolean flip) · `branch` (force an `if` test to `True`/`False`)
· `range_bound` (each `range` argument ±1) · `sort` (reverse it, drop it, `sort(reverse=True)`) ·
`minmax` (`min`↔`max`) · `quantifier` (`all`↔`any`) · `slice` (bound +1) · `return_const` (return
the answer to the *first* recorded input, always — the sharpest probe for a spec that only bounds
its output).

Sampling is deterministic and round-robin across operators, so a file with two hundred integer
literals does not spend the whole budget on constant bumps.

Each mutant is classified:

| verdict | meaning |
|---|---|
| **KILLED** | some contract fired, or some `Ensures` was false |
| **SURVIVED** | it returned a **wrong answer** that every contract accepted — the damning case |
| **CRASHED** | it only ever raised or hung, so the specification never got a say |
| **EQUIVALENT** | no recorded input tells it apart from the reference |

**score = KILLED / (KILLED + SURVIVED)**. Crashed and equivalent mutants are excluded: a spec is
never credited for a mutant it was not given a chance to reject, and never penalised for a mutant
that is not actually wrong. The report keeps up to eight surviving mutants verbatim (operator, line,
the input, what it returned, what was correct) — those strings are the highest-value repair
feedback the pipeline produces.

Mutation score is **reported always** and **gated only on request**
(`--min-mutation-score`), because the right threshold depends on the function: a genuine growth
bound on `fib` is a legitimate spec that no amount of prompting turns into a closed form.

### 4. Critic (`llm_io.py`) — advisory, never a gate

The only question left after the first three gates is one no parser or test run can answer: *does
this specification capture what the function is FOR, or an incidental property that happens to
hold?* The critic is asked exactly that, told that well-formedness / behaviour / truth are already
established, and returns JSON (`captures_intent`, `score`, `missing_property`, `reason`). Its
`missing_property` becomes one more line of repair feedback. It cannot pass or fail a unit.

## The loop (`pipeline.py`)

```
solution_contracts.py (or nothing yet) ──▶ gates ──▶ pass & score ok? ──▶ done
                                             │ no
                                             ▼
                               specific diagnostics (failing input, false
                               clause, unbound name, the wrong implementation
                               your spec accepted, critic's missing property)
                                             │
                                             ▼
                                  generate (bounded to --attempts)
                                             │
                                             ▼
                                           gates ──▶ keep the better of the two
```

Generation and repair are the same step: a unit with no contracts file starts with an empty
history, so its first attempt is a fresh annotation; a unit with a failing file starts with the
diagnostics in hand. Nothing else differs.

Execution-guided repair, in the [Reflexion](https://arxiv.org/abs/2303.11366) /
[Self-Debugging](https://arxiv.org/abs/2304.05128) shape — with the reflection produced by a
verifier rather than by the model reflecting on itself, which is what makes it trustworthy. The
repair prompt states plainly that the findings are facts, and that a "your spec accepts this wrong
implementation" finding must be answered by making the spec **stronger**, not by weakening it until
the complaint goes away.

Candidates are ranked `(passes, mutation score, substantive Ensures, −warnings)`; the best is kept.
Nothing is written unless the winner passes every hard gate, and unless `--in-place` is given the
output goes to `PastaBench/_contract_qa/<Module>.contracts.py` so a sweep can never clobber a
hand-edited file.

## How many LLM calls

`--attempts` is the only knob, and it is a hard per-unit ceiling.

| mode | calls per unit |
|---|---|
| `--attempts 0` | **0** — all four deterministic gates, nothing else |
| a unit that already passes | **0**, at any `--attempts` |
| a unit that needs work | 1 generation per attempt, so ≤ `--attempts` |
| `--critic` as well | + 1 per attempt *after the first* (there is nothing to critique before) |

So a full 164-unit HumanEval sweep at `--attempts 2` with 30 already-failing units costs at most 60
calls, not 328; the gates decide who gets asked. The run prints `[*] LLM calls: N` and each unit's
report carries its own `llm_calls`, so the number is observed rather than estimated. With no key
configured for the provider the sweep says so once and degrades to `--attempts 0` rather than
failing 164 times.

## Running it

```bash
# verify only — deterministic, zero LLM calls, no API key needed
python3 PastaBench/pastabench.py contracts --track humaneval --attempts 0 --report /tmp/qa.json
python3 PastaBench/pastabench.py contracts --track humaneval --only ChangeBase Fib --attempts 0 -v

# write/repair too (needs GEMINI_API_KEY / OPENAI_API_KEY / …)
python3 PastaBench/pastabench.py contracts --track humaneval --attempts 2 --min-mutation-score 0.6
python3 PastaBench/pastabench.py contracts --track humaneval --attempts 2 --critic --in-place
```

Output columns: `STATUS  n_ok/n_tests  E<substantive Ensures>  mut <score> (killed/effective)
W<warnings>  Module`.

Gate tests: `.venv/bin/python tests/test_contract_qa.py` — one case per defect class above, plus
a strong-spec-outscores-weak-spec mutation assertion. No API key, no Lean.

## Design notes

- **No LLM judgement where a parser or a test run suffices.** Every gate but the critic is
  deterministic and reproducible, so a verdict can be re-derived and a regression bisected.
- **The oracle is the reference solution, not the recorded strings.** `tests.json` records a
  `repr`; comparing values sidesteps formatting differences and gives the mutation gate a real
  oracle for "this mutant is genuinely wrong".
- **Conservative scoring.** Everything ambiguous (a mutant that only crashes, a mutant no test
  distinguishes) is excluded rather than counted as a kill.
- **`Ensures` is checked outside the program.** The shim cannot check it — `Result()` does not
  exist yet at the point the argument is evaluated — so the pipeline extracts each clause, rebinds
  `Result()`, and evaluates it against the real return value.
- **Related work.** Specification mining and dynamic invariant inference (Daikon, Ernst et al.) go
  the other way — infer candidate invariants from runs, then filter. Here the candidates come from
  an LLM and the *filtering* is the contribution; mutation testing supplies the non-vacuity signal
  Daikon gets from its statistical confidence tests. Property-based testing (Hypothesis) would be a
  natural extension for generating inputs beyond the recorded fifty (see below).

## Known limits

- Inputs are the recorded `tests.json` cases only. A postcondition false on an input no recorded
  test reaches still passes gate 2. Generating inputs (Hypothesis, or fuzzing the recorded shapes)
  is the obvious next step and is not implemented.
- Mutants are single-point and syntactic; a spec can score 1.00 and still miss a property no
  operator perturbs. The score is a lower bound on spec strength, never a proof of adequacy.
- `lowerability` findings are a static approximation of what degrades codegen; the authority is a
  real translation, which this pipeline deliberately does not run (it is slow and needs the Lean
  backend). Run `pastabench.py regen` for that.
- The gates say nothing about *provability*. A true, non-vacuous, well-scoped contract can still
  defeat `mvcgen` plus the tactic portfolio.
