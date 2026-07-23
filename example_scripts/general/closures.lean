import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

def functions_append_closure :=
  ((do
      let mut f := []
      for i in (PastaLean.pyRange (3 : Int))do
        f := PastaLean.pyAppend f fun () ↦ s! "Function {i}"
      for i in (PastaLean.pyRange (3 : Int))do
        f :=
          PastaLean.pyAppend f fun () ↦
            let i := i
            s! "Function {i}"
      for func in (PastaLean.pyIter f)do
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (func ())]) :
    PastaLean.ProofMode.PyProofM _)

attribute [simp] functions_append_closure

def functions_append_closure'rn :=
  ((do
      let mut f := []
      for i in (PastaLean.pyRange (3 : Int))do
        f := PastaLean.pyAppend f fun () ↦ s! "Function {i}"
      for i in (PastaLean.pyRange (3 : Int))do
        f :=
          PastaLean.pyAppend f fun () ↦
            let i := i
            s! "Function {i}"
      for func in (PastaLean.pyIter f)do
        let _ ← pyPrintIO [pyPrintArg (func ())]) :
    IO _)