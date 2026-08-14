import Libraries.random.RandomDef
import PastaLean.PyAPI.ProofMode.InputM

/-! Proof-mode (`PyProofM`) twin of `random`.

In proof mode the program runs in `PyProofM = ExceptT PyException (StateM IOState)`, which is pure,
so the run-mode `IO`-over-`IO.Ref` generator cannot be used (`← IO _` does not lift into `PyProofM`).
These twins thread the SAME LCG (`Libraries.random.lcgStep`) through `IOState.seed`, so proof-mode
`random.*` is deterministic and provable while matching run mode's generator step-for-step. Codegen
selects these over the `IO` versions whenever `shouldUseProofMonad` (see `pythonLibraryMapProof?`). -/

namespace Libraries.random

open PastaLean.ProofMode

/-- Advance the proof-mode generator (state-threaded twin of `nextState`). -/
def nextStateProof : PyProofM Nat := fun s =>
  let s' := lcgStep s.seed
  (Except.ok s', { s with seed := s' })

/-- `random.seed(n)` (proof mode). -/
def pyRandomSeedProof (n : Int) : PyProofM Unit := fun s =>
  (Except.ok (), { s with seed := n.natAbs })

/-- `random.random()` (proof mode) — a float in `[0, 1)`. -/
def pyRandomRandomProof : PyProofM Float := do
  let s ← nextStateProof
  return (Float.ofNat (s / 2048) / Float.ofNat 9007199254740992)

/-- `random.randint(a, b)` (proof mode) — an int in `[a, b]` inclusive. -/
def pyRandomRandintProof (a b : Int) : PyProofM Int := do
  if b < a then return a
  let s ← nextStateProof
  return a + (Int.ofNat (s % (b - a + 1).toNat))

/-- `random.randrange(stop[, start])` (proof mode) — an int in `[start, stop)`. -/
def pyRandomRandrangeProof (stop : Int) (start : Int := 0) : PyProofM Int := do
  if stop ≤ start then return start
  let s ← nextStateProof
  return start + (Int.ofNat (s % (stop - start).toNat))

/-- `random.choice(xs)` (proof mode). -/
def pyRandomChoiceProof {α : Type} [Inhabited α] (xs : List α) : PyProofM α := do
  if xs.isEmpty then return default
  let s ← nextStateProof
  return xs[s % xs.length]!

/-- `random.shuffle(xs)` (proof mode) — Fisher-Yates, returning the shuffled list. -/
def pyRandomShuffleProof {α : Type} [Inhabited α] (xs : List α) : PyProofM (List α) := do
  let mut arr := xs.toArray
  for i in [0:arr.size] do
    let j := arr.size - 1 - i
    if j = 0 then break
    let s ← nextStateProof
    let k := s % (j + 1)
    arr := arr.swapIfInBounds j k
  return arr.toList

/-- `random.sample(xs, k)` (proof mode) — `k` distinct elements. -/
def pyRandomSampleProof {α : Type} [Inhabited α] (xs : List α) (k : Int) : PyProofM (List α) := do
  let shuffled ← pyRandomShuffleProof xs
  return shuffled.take k.toNat

/-- `random.uniform(a, b)` (proof mode) — a float in `[a, b]`. -/
def pyRandomUniformProof (a b : Float) : PyProofM Float := do
  let r ← pyRandomRandomProof
  return a + (b - a) * r

end Libraries.random
