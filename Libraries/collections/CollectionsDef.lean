import PastaLean.Imports
import PastaLean.PyAPI

namespace Libraries.collections

open PastaLean

/-- A dict whose missing keys read as `dflt` instead of raising `KeyError`. Models both
`collections.Counter` (`dflt = 0`) and `collections.defaultdict(f)` (`dflt = f ()`).

`order` lists the keys by first insertion, so `keys`/`values`/`items`/iteration match Python's
insertion-ordered dicts rather than the hash order of `map`. -/
structure PyDefaultDict (κ ν : Type) [BEq κ] [Hashable κ] where
  map : Std.HashMap κ ν
  order : List κ
  dflt : ν

variable {κ ν : Type} [BEq κ] [Hashable κ]

/-- `defaultdict(f)` / `Counter()`: empty, reading missing keys as `dflt`. -/
def PyDefaultDict.empty (dflt : ν) : PyDefaultDict κ ν := ⟨∅, [], dflt⟩

/-- An empty default-dict whose missing-key default is the value type's own `default` (`0` for a
`Counter`, `[]` for `defaultdict(list)`). Lets a hoisted `let mut d : PyDefaultDict _ _ := default`
resolve — the block later rebinds it to the real `Counter(...)`. -/
instance [Inhabited ν] : Inhabited (PyDefaultDict κ ν) := ⟨PyDefaultDict.empty default⟩

/-- Set `k` to `v`, recording `k` at the end of `order` when it is new. -/
def PyDefaultDict.insert (d : PyDefaultDict κ ν) (k : κ) (v : ν) : PyDefaultDict κ ν :=
  { d with
    map := d.map.insert k v,
    order := if d.map.contains k then d.order else d.order ++ [k] }

/-- The `(key, value)` pairs in insertion order. -/
def PyDefaultDict.toPairs (d : PyDefaultDict κ ν) : List (κ × ν) :=
  d.order.filterMap (fun k => (d.map.get? k).map (fun v => (k, v)))

/-- `d.pop(key)` on a `defaultdict`/`Counter`: the value at `key`, and the dict without it (dropped
from both the map and the insertion order). -/
instance [Inhabited ν] : PastaLean.PyDictKeyPop (PyDefaultDict κ ν) κ ν where
  keyPopValue d key := d.map.getD key default
  keyGetOr d key dflt := (d.map.get? key).getD dflt
  keyPopRest d key := { d with map := d.map.erase key, order := d.order.filter (· != key) }

/-- Count occurrences of each element: `ofIterable ['a','b','a'] = {'a' ↦ 2, 'b' ↦ 1}`. -/
def PyDefaultDict.ofIterable {α : Type} [PyIterable α κ] (xs : α) : PyDefaultDict κ Int :=
  (pyIter xs).foldl (fun d k => d.insert k (d.map.getD k 0 + 1)) (PyDefaultDict.empty 0)

/-- `Counter.most_common(n)`: the `(key, count)` pairs from highest count down, keeping the first `n`
(all of them when `n` is negative, the default the codegen passes for the no-argument `most_common()`).
`mergeSort` is stable, so ties keep insertion order — matching CPython 3.7+. -/
def pyMostCommon (c : PyDefaultDict κ Int) (n : Int := -1) : List (κ × Int) :=
  let sorted := c.toPairs.mergeSort (fun a b => decide (a.2 ≥ b.2))
  if n < 0 then sorted else sorted.take n.toNat

/-- `Counter.elements()`: each key repeated `count` times, in insertion order (counts ≤ 0 contribute
nothing, as in CPython). -/
def pyElements (c : PyDefaultDict κ Int) : List κ :=
  c.toPairs.flatMap (fun (k, cnt) => List.replicate cnt.toNat k)

/-- `collections.defaultdict(list)`. -/
def pyDefaultDictList : PyDefaultDict κ (List ν) := PyDefaultDict.empty []

/-- `collections.defaultdict(int)`. -/
def pyDefaultDictInt : PyDefaultDict κ Int := PyDefaultDict.empty 0

/-- `collections.Counter()`. -/
def pyCounterEmpty : PyDefaultDict κ Int := PyDefaultDict.empty 0

/-- `collections.defaultdict(dict)` — each missing key defaults to an empty mapping. -/
def pyDefaultDictDict [BEq α] [Hashable α] : PyDefaultDict κ (Std.HashMap α ν) :=
  PyDefaultDict.empty ∅

/-- `collections.defaultdict(Counter)` — each missing key defaults to an empty counter. -/
def pyDefaultDictCounter [BEq α] [Hashable α] : PyDefaultDict κ (PyDefaultDict α Int) :=
  PyDefaultDict.empty (PyDefaultDict.empty 0)

/-- `collections.Counter(xs)`. -/
def pyCounter {α : Type} [PyIterable α κ] (xs : α) : PyDefaultDict κ Int :=
  PyDefaultDict.ofIterable xs

/-- `collections.deque()`. Deques are `List`-backed, so every list protocol applies to them. -/
def pyDequeEmpty {α : Type} : List α := []

/-- `collections.deque(xs)`: `pyDeque "ab" = ["a", "b"]`. -/
def pyDeque {α β : Type} [PyIterable α β] (xs : α) : List β := pyIter xs

/-- `d[k]` yields `d.dflt` when `k` is absent; unlike Python it does not insert the key. -/
instance : PyGetItem (PyDefaultDict κ ν) κ ν where
  getItem d k := d.map.getD k d.dflt

instance : PySetItem (PyDefaultDict κ ν) κ ν where
  setItem d k v := d.insert k v

instance : PyLen (PyDefaultDict κ ν) where
  pyLen d := d.map.size

instance : PyIterable (PyDefaultDict κ ν) κ where
  toPyList d := d.order

instance : PyContains (PyDefaultDict κ ν) κ where
  contains d k := d.map.contains k

instance : PyClear (PyDefaultDict κ ν) where
  pyClear d := { d with map := ∅, order := [] }

instance : PyItems (PyDefaultDict κ ν) κ ν where
  pyItems d := d.toPairs

instance : PyKeys (PyDefaultDict κ ν) κ where
  pyKeys d := d.order

instance : PyAnys (PyDefaultDict κ ν) ν where
  pyAnys d := d.toPairs.map Prod.snd

-- `sorted(d)` sorts a dict's KEYS (matching `Std.HashMap`), so a `defaultdict`/`Counter` iterated as
-- `for x in sorted(d)` resolves.
instance [Ord κ] : PySort (PyDefaultDict κ ν) κ where
  pySort d := d.order.mergeSort pyOrdLe

-- `if d:` / `while d:` — a dict is truthy iff non-empty (Python).
instance : PyTruthy (PyDefaultDict κ ν) where
  truthy d := !d.order.isEmpty

-- `del d[k]` drops the key from both the map and the insertion order.
instance : PyDelItem (PyDefaultDict κ ν) κ where
  delItem d k := { d with map := d.map.erase k, order := d.order.filter (· != k) }

end Libraries.collections
