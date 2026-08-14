import Libraries.itertools.ItertoolsDef
import Libraries.Mutator
import Libraries.Behaviour

namespace Libraries.itertools
open Libraries TypeInfer

/-- Map supported `itertools` members to the Lean runtime helpers they lower to. Members whose call
needs custom lowering — variadic (`chain`/`product`/`zip_longest`), a predicate/function argument
(`dropwhile`/`takewhile`/`filterfalse`/`starmap`), or `accumulate(initial=…)` — are handled in
`PyGens/Calls/SpecialCalls/Itertools.lean` instead and are intentionally absent here. -/
def pythonItertoolsMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "accumulate"    => some ``Libraries.itertools.pyAccumulate
  | "pairwise"      => some ``Libraries.itertools.pyPairwise
  | "compress"      => some ``Libraries.itertools.pyCompress
  | "combinations"  => some ``Libraries.itertools.pyCombinations
  | "combinations_with_replacement" => some ``Libraries.itertools.pyCombinationsWithReplacement
  | "permutations"  => some ``Libraries.itertools.pyPermutations
  | "groupby"       => some ``Libraries.itertools.pyGroupby
  | "batched"       => some ``Libraries.itertools.pyBatched
  | "tee"           => some ``Libraries.itertools.pyTee
  | "repeat"        => some ``Libraries.itertools.pyRepeat
  | "islice"        => some ``Libraries.itertools.pyIslice
  | _ => none

/-- The full behaviour of each `itertools` member: return shape for inference (`chain` → list of the
common element type; `product` → list of Cartesian-product tuples; `accumulate` → running fold;
`pairwise` → consecutive `(elem, elem)` pairs), and the unbounded-iterator shape for the desugarer
(`count`/`cycle`/`repeat`, the last only in its 1-argument form — the desugaring checks arity). -/
def itertoolsBehaviour? (member : String) : Option Behaviour :=
  open Behaviour in
  match member with
  | "chain"      => some listOfJoined
  | "product"    => some listOfTuples
  | "accumulate" => some (listOf 0)
  | "pairwise"   => some adjacentPairs
  | "count"      => some { infiniteIter := some .counter }
  | "cycle"      => some { infiniteIter := some .cyclic }
  | "repeat"     => some { infiniteIter := some .constant }
  | _ => none

end Libraries.itertools
