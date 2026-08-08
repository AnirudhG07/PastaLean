import PastaLean.Imports

namespace Libraries.random

/-! Python's `random` module.

Python's RNG is a single piece of global mutable state, so these live in `IO` over an `IO.Ref`
rather than being pure — the same treatment `input()` gets. Consequence: a function that draws a
random number becomes IO-effectful and leaves the pure/provable track. That is inherent to
randomness, not an artifact of the modelling.

The generator is a 64-bit LCG (Knuth's MMIX constants), NOT CPython's Mersenne Twister, so
sequences do not match CPython for a given seed. Callers that only need "some value in range"
(Miller-Rabin witnesses, sampling) behave correctly; anything asserting a specific seeded sequence
does not. -/

/-- 2^64, the LCG modulus. -/
private def twoPow64 : Nat := 18446744073709551616

/-- One step of the LCG: `s ↦ 6364136223846793005·s + 1442695040888963407 (mod 2^64)`. -/
def lcgStep (s : Nat) : Nat := (6364136223846793005 * s + 1442695040888963407) % twoPow64

/-- The global generator state, mirroring Python's module-level RNG. -/
initialize seedRef : IO.Ref Nat ← IO.mkRef 5489

/-- Advance the generator and return the new state. -/
def nextState : IO Nat := do
  let s ← seedRef.get
  let s' := lcgStep s
  seedRef.set s'
  return s'

/-- `random.seed(n)`. -/
def pyRandomSeed (n : Int) : IO Unit := seedRef.set n.natAbs

/-- `random.random()` — a float in `[0, 1)`. Uses the top 53 bits, as CPython does. -/
def pyRandomRandom : IO Float := do
  let s ← nextState
  return (Float.ofNat (s / 2048) / Float.ofNat 9007199254740992)

/-- `random.randint(a, b)` — an int in `[a, b]` INCLUSIVE. `b < a` is a Python `ValueError`; here
it yields `a`, keeping the function total. -/
def pyRandomRandint (a b : Int) : IO Int := do
  if b < a then return a
  let s ← nextState
  return a + (Int.ofNat (s % (b - a + 1).toNat))

/-- `random.randrange(stop)` / `random.randrange(start, stop)` — an int in `[start, stop)`. -/
def pyRandomRandrange (stop : Int) (start : Int := 0) : IO Int := do
  if stop ≤ start then return start
  let s ← nextState
  return start + (Int.ofNat (s % (stop - start).toNat))

/-- `random.choice(xs)` — a uniformly chosen element. Empty input is a Python `IndexError`; here it
returns `default`, matching the rest of the runtime's total-function convention. -/
def pyRandomChoice {α : Type} [Inhabited α] (xs : List α) : IO α := do
  if xs.isEmpty then return default
  let s ← nextState
  return xs[s % xs.length]!

/-- `random.shuffle(xs)`: a Fisher-Yates permutation. Python shuffles in place and returns `None`;
codegen rebinds the receiver, so this returns the shuffled list. -/
def pyRandomShuffle {α : Type} [Inhabited α] (xs : List α) : IO (List α) := do
  let mut arr := xs.toArray
  for i in [0:arr.size] do
    let j := arr.size - 1 - i
    if j = 0 then break
    let s ← nextState
    let k := s % (j + 1)
    arr := arr.swapIfInBounds j k
  return arr.toList

/-- `random.sample(xs, k)` — `k` distinct elements. Shuffle and take, so the elements are distinct
exactly as Python guarantees. -/
def pyRandomSample {α : Type} [Inhabited α] (xs : List α) (k : Int) : IO (List α) := do
  let shuffled ← pyRandomShuffle xs
  return shuffled.take k.toNat

/-- `random.uniform(a, b)` — a float in `[a, b]`. -/
def pyRandomUniform (a b : Float) : IO Float := do
  let r ← pyRandomRandom
  return a + (b - a) * r

end Libraries.random
