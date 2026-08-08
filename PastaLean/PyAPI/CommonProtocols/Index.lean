import PastaLean.Imports
import PastaLean.PyAPI.Strings
import PastaLean.PyAPI.Lists

namespace PastaLean
class PyIndex (α β: Type) where
  /-- For `index()`, return the index of the first occurrence at or after `start`. -/
  pyIndex : α → β → Int → Int

/- Public runtime for `index()`; Python's optional `start` (`s.index(sub, i)`) defaults to 0. -/
def pyIndex {α β} [PyIndex α β] (a : α) (b : β) (start : Int := 0) : Int :=
  PyIndex.pyIndex a b start

instance [DecidableEq α] : PyIndex (List α) α where
  pyIndex xs elem start :=
    if start ≤ 0 then pyListIndex xs elem
    else match pyListIndex (xs.drop start.toNat) elem with
      | -1 => -1
      | i => i + start

instance : PyIndex String String where
  pyIndex s sub start := pyStringIndex s sub start

end PastaLean
