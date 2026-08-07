import Libraries.random.RandomDef

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

end Libraries.random
