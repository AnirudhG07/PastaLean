import Libraries.heapq.HeapqDef
import Libraries.Mutator
import Libraries.Behaviour

namespace Libraries.heapq
open Libraries TypeInfer

/-- Map the pure `heapq` members (return a value, no mutation) to their runtime helpers. The mutating
members (`heapify`/`heappush`/`heappop`) are declared in `heapqMutator?` below and lowered generically
by the core codegen. -/
def pythonHeapqMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "nsmallest" => some ``Libraries.heapq.pyNsmallest
  | "nlargest"  => some ``Libraries.heapq.pyNlargest
  | _ => none

/-- The `heapq` members that mutate their heap argument in place. -/
def heapqMutator? (member : String) : Option Libraries.LibraryMutator :=
  match member with
  | "heapify"  => some { stmtFn := ``pyHeapify }
  | "heappush" => some { stmtFn := ``pyHeappush }
  | "heappop"  => some { stmtFn := ``pyHeappopRest, valueRest? := some (``pyHeappopVal, ``pyHeappopRest) }
  | "heapreplace" => some { stmtFn := ``pyHeapreplaceRest, valueRest? := some (``pyHeapreplaceVal, ``pyHeapreplaceRest) }
  | _ => none

/-- Inference behaviour of `heapq` members: `heappop`/`heapreplace` return the heap's element type, so
`w, a = heappop(pq)` (and anything computed from `w`) is typed; `heappush(h, x)`/`heappushpop(h, x)`
`teaches?` `h` (arg 0) that it holds `x` (arg 1) — driving the widening chain (a heap of `(int, int)`
pushed a `(ℚ, int)` widens). This is the inference twin of `heapqMutator?`. -/
def heapqBehaviour? (member : String) : Option Behaviour :=
  open Behaviour in
  match member with
  | "heappop" | "heapreplace" => some (elementOf 0)
  | "heappush"                => some (push 0 1)
  | "heappushpop"             => some { elementOf 0 with teaches? := some (0, 1) }  -- returns AND pushes
  | _ => none

end Libraries.heapq
