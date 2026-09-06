import PastaLean.PyAPI.Lists
import PastaLean.PyAPI.Arrays
import PastaLean.PyAPI.Core
import PastaLean.PyAPI.PyAny

open PastaLean

/-- info: [1, 2, 3, 4] -/
#guard_msgs in
#eval pyAppend [1, 2, 3] 4

/-- info: ["solo"] -/
#guard_msgs in
#eval pyAppend [] "solo"

/-- info: [1, 2, 3, 4, 5] -/
#guard_msgs in
#eval pyExtend [1, 2] [3, 4, 5]

/-- info: [1, 2] -/
#guard_msgs in
#eval pyExtend [1, 2] []

/-- info: (some 30, [10, 20, 40]) -/
#guard_msgs in
#eval pyListPop [10, 20, 30, 40] 2

/-- info: (some 99, [7, 8]) -/
#guard_msgs in
#eval pyListPop [7, 8] 5 (some 99)

/-- info: 1 -/
#guard_msgs in
#eval pyListIndex ["red", "blue", "green"] "blue"

/-- info: 3 -/
#guard_msgs in
#eval pyListCount [1, 2, 2, 3, 2] 2

/-- info: 0 -/
#guard_msgs in
#eval pyListCount ["a", "b"] "z"

/-- info: [4, 3, 2, 1] -/
#guard_msgs in
#eval pyReverse [1, 2, 3, 4]

/-- info: [] -/
#guard_msgs in
#eval pyReverse ([] : List Int)

/-- info: [] -/
#guard_msgs in
#eval pyListClear [1, 2, 3]

/-- info: ["x"] -/
#guard_msgs in
#eval pyInsert [] 0 "x"

/-- info: [1, 99, 2, 3] -/
#guard_msgs in
#eval pyInsert [1, 2, 3] 1 99

/-- info: [42, 1, 2, 3] -/
#guard_msgs in
#eval pyInsert [1, 2, 3] (-5) 42

/-- info: [1, 2, 3, 42] -/
#guard_msgs in
#eval pyInsert [1, 2, 3] 99 42

/-! ### Array-backed sequences (`'rn` twin) — numerical parity with the `List` ops.

The runnable twin backs Python `list` with `Array α` for O(1) append/index (vs `List`'s O(n)),
using the same value-semantics-plus-reassignment model — so results must be identical. These are
the HOT ops we port (`append`/`get`/`set`/`repeat`/`extend`); List-only ops fall back to `List`.
The final `#guard` is the load-bearing invariant: an Array build→append→index→sum equals the List
one (and the closed form), so a divergence between the twins is caught here. -/

/-- info: #[1, 2, 3, 4] -/
#guard_msgs in
#eval pyArrayAppend #[1, 2, 3] 4

/-- info: #[10, 99, 30] -/
#guard_msgs in
#eval pyArraySetItem #[10, 20, 30] 1 99

/-- info: #[10, 20, 77] -/
#guard_msgs in
#eval pyArraySetItem #[10, 20, 30] (-1) 77

/-- info: 30 -/
#guard_msgs in
#eval pyArrayGetItem #[10, 20, 30] 2

/-- info: 20 -/
#guard_msgs in
#eval pyArrayGetItem #[10, 20, 30] (-2)

/-- info: #[0, 0, 0, 0] -/
#guard_msgs in
#eval pyArrayRepeat #[(0 : Int)] 4

/-- info: #[1, 2, 3, 4, 5] -/
#guard_msgs in
#eval pyArrayExtend #[1, 2] #[3, 4, 5]

-- Array twin (O(1) append/index) and List twin (O(n)) agree on a build→append→index→sum, and both
-- equal the closed form `∑_{i<n} i = n(n-1)/2`. Witnesses semantic parity of the two backings.
#guard
  let n := 50
  let arrSum := Id.run do
    let mut xs : Array Int := #[]
    for i in [0:n] do xs := pyArrayAppend xs (i : Int)
    let mut s : Int := 0
    for i in [0:n] do s := s + pyArrayGetItem xs (i : Int)
    return s
  let listSum := Id.run do
    let mut xs : List Int := []
    for i in [0:n] do xs := pyAppend xs (i : Int)
    let mut s : Int := 0
    for i in [0:n] do s := s + pyListGetItem xs (i : Int)
    return s
  (arrSum == listSum) && (arrSum == 1225)

/-! ### Nested `Array` and `Array (Array PyAny)` — the runnable twin backs `list[list[T]]` as
`Array (Array T)`, including boxed `PyAny` elements, through the same polymorphic protocols. -/

/-- info: #[#[1, 2], #[3, 4, 5]] -/
#guard_msgs in
#eval pyArraySetItem #[#[1, 2], #[3, 4]] 1 (pyArrayAppend #[3, 4] 5)   -- m[1] = [3,4] + [5]

-- Nested `Array (Array Int)` matrix access: `m[0][0] = 100` then index reads back (the codegen path
-- `pySetItem m i (pySetItem m[i] j v)` on `Array (Array Int)`).
#guard
  let m : Array (Array Int) := #[#[1, 2, 3], #[4, 5, 6], #[7, 8, 9]]
  let m := pyArraySetItem m 0 (pyArraySetItem m⦋(0:Int)⦌ 0 100)   -- m[0][0] = 100
  (m⦋(0:Int)⦌⦋(0:Int)⦌ == 100) && (m⦋(2:Int)⦌⦋(1:Int)⦌ == 8)
    && (pyLen m == 3) && (pyLen m⦋(0:Int)⦌ == 3)

-- `Array PyAny` and `Array (Array PyAny)`: boxed elements flow through get/set/append/len/contains.
#guard
  let flat : Array PyAny := pyArrayAppend #[PyAny.int 1, PyAny.str "a"] (PyAny.bool true)
  let m : Array (Array PyAny) := #[#[PyAny.int 1], #[PyAny.int 4]]
  let m := pyArraySetItem m 1 (pyArrayAppend m⦋(1:Int)⦌ (PyAny.int 9))   -- m[1].append(9)
  (pyLen flat == 3) && (flat⦋(2:Int)⦌ == PyAny.bool true)
    && (m⦋(1:Int)⦌⦋(1:Int)⦌ == PyAny.int 9) && (pyLen m⦋(1:Int)⦌ == 2)
    && (pyContains m⦋(0:Int)⦌ (PyAny.int 1))

/-! Python slicing clamps out-of-range bounds instead of failing, counts negative bounds from the
end, and reverses on a negative step. -/

#guard pyListSliceStep [1, 2, 3, 4, 5] (some (-2)) none (some 1) == [4, 5]    -- xs[-2:]
#guard pyListSliceStep [1, 2, 3, 4, 5] (some 2) (some 100) none == [3, 4, 5]  -- xs[2:100]
#guard pyListSliceStep [1, 2, 3] none none (some (-1)) == [3, 2, 1]           -- xs[::-1]
