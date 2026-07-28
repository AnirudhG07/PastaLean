import Libraries.itertools.ItertoolsDef
import Libraries.Mutator

namespace Libraries.itertools

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

/-- The `itertools` iterators that never end. `repeat` is here only in its 1-argument form; with a
count it is finite and uses `pyRepeat` above, so the desugaring checks the arity. -/
def itertoolsInfiniteIter? (member : String) : Option Libraries.InfiniteIter :=
  match member with
  | "count"  => some .counter
  | "cycle"  => some .cyclic
  | "repeat" => some .constant
  | _ => none

end Libraries.itertools
