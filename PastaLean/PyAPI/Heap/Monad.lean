import PastaLean.PyAPI.Heap.Ops
import PastaLean.PyAPI.ProofMode.InputM

/-!
# Heap runtime — monad composition

The pure `HeapM V` (heap + `PyException`) is the analog of `PyExceptId`. When a heap program also
does IO we compose:

* **run mode** — `PyHeapIO V := ExceptT PyException (StateT (Heap V) IO)` (mirrors
  `PyExcept = ExceptT PyException IO`, with a `StateT (Heap V)` inserted).
* **prove mode** — `PyHeapProofM V := ExceptT PyException (StateM (HeapIOState V))`, where the state
  carries both the heap and the existing proof-mode `IOState` (mirrors
  `PyProofM = ExceptT PyException (StateM IOState)`).

The `MonadLift` instances (modeled on `MonadLift InputM PyProofM`) let generated code call `alloc`/
`readRef`/… (which live in `HeapM V`) and `input`/`print` inside these bodies with a plain `←`.
-/

namespace PastaLean

open PastaLean.ProofMode

/-- Run-mode monad for heap programs that also do IO. -/
abbrev PyHeapIO (V : Type) (α : Type) := ExceptT PyException (StateT (Heap V) IO) α

/-- The combined proof-mode state: the heap plus the observable IO stream/output. -/
structure HeapIOState (V : Type) where
  heap : Heap V
  io   : IOState

/-- Prove-mode monad for heap programs with observable IO (pure state, no real IO). -/
abbrev PyHeapProofM (V : Type) (α : Type) := ExceptT PyException (StateM (HeapIOState V)) α

variable {V α : Type}

/-- Lift a pure `HeapM` action into the run-mode `PyHeapIO` stack, threading the heap state. -/
def liftHeapToIO (m : HeapM V α) : PyHeapIO V α := fun h => pure (runFrom m h)

/-- Lift a pure `HeapM` action into the prove-mode `PyHeapProofM` stack, acting on the `heap` slot. -/
def liftHeapToProof (m : HeapM V α) : PyHeapProofM V α := fun st =>
  let (result, h') := runFrom m st.heap
  (result, { st with heap := h' })

/-- Lift a proof-mode `InputM` action (IO-as-state) into `PyHeapProofM`, acting on the `io` slot and
converting IO errors into catchable `PyException`s (the analog of `PyProofM.liftInputM`). -/
def liftInputToHeapProof (action : InputM α) : PyHeapProofM V α := fun st =>
  let (result, io') := action st.io
  match result with
  | .ok val      => (.ok val, { st with io := io' })
  | .error ioErr => (.error ioErr.toPyException, { st with io := io' })

/-- Lift a proof-mode `PyProofM` action (e.g. `pyPrintProof`) into `PyHeapProofM`, acting on the `io`
slot. Both monads throw `PyException`, so the result passes through untouched (unlike
`liftInputToHeapProof`, no `IOError → PyException` conversion is needed). This is what lets a
prove-mode heap `main` call `print` with a plain `←`. -/
def liftProofToHeapProof (m : PyProofM α) : PyHeapProofM V α := fun st =>
  let (result, io') := m st.io
  (result, { st with io := io' })

instance : MonadLift (HeapM V) (PyHeapIO V) where monadLift := liftHeapToIO
instance : MonadLift (HeapM V) (PyHeapProofM V) where monadLift := liftHeapToProof
instance : MonadLift InputM (PyHeapProofM V) where monadLift := liftInputToHeapProof
instance : MonadLift PyProofM (PyHeapProofM V) where monadLift := liftProofToHeapProof

/-- Run `body`, converting an underlying `IO` error (e.g. `EOFError` from `input()` at end of input)
into a catchable `PyException` — the `PyHeapIO` analog of `PyExcept.captureIOErrors`. A `try` body
that does IO wraps each `(← …)` await with this so IO errors surface to the translated `catch`;
heap-call awaits (which already raise `PyException` in the `ExceptT` layer) pass through untouched. -/
def PyHeapIO.captureIOErrors (body : PyHeapIO V α) : PyHeapIO V α :=
  ExceptT.mk (StateT.mk (fun h =>
    try StateT.run (ExceptT.run body) h
    catch e : IO.Error => pure (Except.error (PyException.Raise "Exception" (toString e)), h)))

/-- Run a run-mode heap program from the empty heap. -/
def PyHeapIO.runProgram (m : PyHeapIO V α) : IO (Except PyException α × Heap V) :=
  (ExceptT.run m).run emptyHeap

/-- Run a prove-mode heap program from a given combined state. -/
def PyHeapProofM.runProgram (m : PyHeapProofM V α) (init : HeapIOState V) :
    Except PyException α × HeapIOState V :=
  (ExceptT.run m).run init

/-! ## Monad-polymorphic leaf ops (`…M` variants)

The leaf ops (`readRef`/`writeRef`/`modifyRef`/`alloc`) live in `HeapM V`. Inside a `HeapM V` method
body they elaborate directly (the ambient monad head unifies `V`). But in a `main`/IO-effectful body
— `PyHeapIO V` or `PyHeapProofM V` — a *lift* is needed, and the `do` elaborator won't insert a lift
from a metavariable-source monad `HeapM ?V` (nor can `Storable ?V _` resolve while `?V` is unknown).

`IsHeapMonad m V` recovers `V` from the ambient monad `m` (`outParam`), so the `…M` wrappers pin `V`
before lifting. They collapse to the plain op in a `HeapM V` body (reflexive lift = identity), so
codegen can emit them uniformly regardless of the surrounding monad. -/

/-- Recover the heap value-universe `V` from any heap monad `m`. `outParam` so `V` is inferred from
`m`, letting the `…M` ops pin `V` without a type ascription codegen would have to synthesize. -/
class IsHeapMonad (m : Type → Type) (V : outParam Type)
instance : IsHeapMonad (HeapM V) V := ⟨⟩
instance : IsHeapMonad (PyHeapIO V) V := ⟨⟩
instance : IsHeapMonad (PyHeapProofM V) V := ⟨⟩

/-- `readRef` usable in any heap monad `m`; `V` comes from `m` via `IsHeapMonad`. -/
def readRefM {m : Type → Type} [IsHeapMonad m V] [Storable V α] [MonadLiftT (HeapM V) m]
    (r : Ref α) : m α := liftM (readRef (V := V) r)

/-- `writeRef` usable in any heap monad `m`. -/
def writeRefM {m : Type → Type} [IsHeapMonad m V] [Storable V α] [MonadLiftT (HeapM V) m]
    (r : Ref α) (v : α) : m Unit := liftM (writeRef (V := V) r v)

/-- `modifyRef` usable in any heap monad `m`. -/
def modifyRefM {m : Type → Type} [IsHeapMonad m V] [Storable V α] [MonadLiftT (HeapM V) m]
    (r : Ref α) (f : α → α) : m Unit := liftM (modifyRef (V := V) r f)

/-- `alloc` usable in any heap monad `m`. -/
def allocM {m : Type → Type} [IsHeapMonad m V] [Storable V α] [MonadLiftT (HeapM V) m]
    (v : α) : m (Ref α) := liftM (alloc (V := V) v)

end PastaLean
