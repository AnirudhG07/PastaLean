import Libraries.heapq.HeapqDef
import Libraries.Mutator
import Libraries.Behaviour

namespace Libraries.heapq
open Libraries TypeInfer

/-- Map the pure `heapq` members (return a value, no mutation) to their runtime helpers. The mutating
members declare their behaviour (return, teaches, in-place mutation) in `heapqBehaviour?` below. -/
def pythonHeapqMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "nsmallest" => some ``Libraries.heapq.pyNsmallest
  | "nlargest"  => some ``Libraries.heapq.pyNlargest
  | _ => none

/-- The full behaviour of each `heapq` member in one record: what it returns (`heappop`/`heapreplace`
→ the heap's element type, so `w, a = heappop(pq)` is typed), whether it `teaches?` the heap a new
element type (`heappush`/`heappushpop` widen a heap of `(int, int)` pushed a `(ℚ, int)`), and how it
mutates the heap in place at runtime (`mutator`, read by the code generator). -/
def heapqBehaviour? (member : String) : Option Behaviour :=
  open Behaviour in
  match member with
  | "heapify"     => some { mutator := some { stmtFn := ``pyHeapify } }
  | "heappush"    => some { push 0 1 with mutator := some { stmtFn := ``pyHeappush } }
  | "heappop"     => some { elementOf 0 with
                            mutator := some { stmtFn := ``pyHeappopRest, valueRest? := some (``pyHeappopVal, ``pyHeappopRest) } }
  | "heapreplace" => some { elementOf 0 with
                            mutator := some { stmtFn := ``pyHeapreplaceRest, valueRest? := some (``pyHeapreplaceVal, ``pyHeapreplaceRest) } }
  | "heappushpop" => some { elementOf 0 with teaches? := (push 0 1).teaches? }
  -- `nlargest(n, iterable)` / `nsmallest(...)` return a LIST of the iterable's (arg 1) elements —
  -- so `x, y = nlargest(2, nums)` unpacks by index, not as a `Prod`.
  | "nlargest" | "nsmallest" => some (listOf 1)
  | _ => none

end Libraries.heapq
