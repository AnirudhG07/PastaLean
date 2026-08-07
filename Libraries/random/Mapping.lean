import Libraries.random.RandomDef
import Libraries.random.RandomProof

namespace Libraries.random

/-- Map supported `random` members to the Lean runtime helpers they lower to. Every one is `IO`
(the generator is global mutable state), so codegen must treat these calls as effectful — see the
`random` case in `annotate_io_effects` (`src/transpile/driver.py`). -/
def pythonRandomMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "seed"      => some ``Libraries.random.pyRandomSeed
  | "random"    => some ``Libraries.random.pyRandomRandom
  | "randint"   => some ``Libraries.random.pyRandomRandint
  | "randrange" => some ``Libraries.random.pyRandomRandrange
  | "choice"    => some ``Libraries.random.pyRandomChoice
  | "shuffle"   => some ``Libraries.random.pyRandomShuffle
  | "sample"    => some ``Libraries.random.pyRandomSample
  | "uniform"   => some ``Libraries.random.pyRandomUniform
  | _ => none

/-- Proof-mode (`PyProofM`) twins of the `random` members, selected in exact mode (see
`pythonLibraryMapProof?`). Keep in lockstep with `pythonRandomMemberMap?`. -/
def pythonRandomMemberMapProof? (member : String) : Option Lean.Name :=
  match member with
  | "seed"      => some ``Libraries.random.pyRandomSeedProof
  | "random"    => some ``Libraries.random.pyRandomRandomProof
  | "randint"   => some ``Libraries.random.pyRandomRandintProof
  | "randrange" => some ``Libraries.random.pyRandomRandrangeProof
  | "choice"    => some ``Libraries.random.pyRandomChoiceProof
  | "shuffle"   => some ``Libraries.random.pyRandomShuffleProof
  | "sample"    => some ``Libraries.random.pyRandomSampleProof
  | "uniform"   => some ``Libraries.random.pyRandomUniformProof
  | _ => none

end Libraries.random
