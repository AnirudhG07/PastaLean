import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

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

private def _make_adder'add := fun (x : Int) ↦ fun (n : Int) ↦ x +ₚ n

attribute [simp, taste_ingr] _make_adder'add

def make_adder := fun (n : Int) ↦
  -- A closure RETURNED as a value: `add` captures `n`. PastaLean lifts `add` to a provable sibling
  -- and returns `fun x => add x n` (n baked in) — a genuine Lean closure. `make_adder(5)(3) == 8`.
  fun (x : Int) ↦ _make_adder'add x n

attribute [simp, taste_ingr] make_adder

private def _make_adder'add'rn := fun (x : Int) ↦ fun (n : Int) ↦ x +ₚ n

def make_adder'rn := fun (n : Int) ↦
  -- A closure RETURNED as a value: `add` captures `n`. PastaLean lifts `add` to a provable sibling
  -- and returns `fun x => add x n` (n baked in) — a genuine Lean closure. `make_adder(5)(3) == 8`.
  fun (x : Int) ↦ _make_adder'add'rn x n

private def _double'wrapper := fun (x : Int) ↦ fun (f : Int → Int) ↦ (2 : Int) *ₚ f x

attribute [simp, taste_ingr] _double'wrapper

def double := fun (f : Int → Int) ↦
  -- A decorator is just a closure returning a wrapper over the decorated function.
  fun (x : Int) ↦ _double'wrapper x f

attribute [simp, taste_ingr] double

private def _double'wrapper'rn := fun (x : Int) ↦ fun (f : Int → Int) ↦ (2 : Int) *ₚ f x

def double'rn := fun (f : Int → Int) ↦
  -- A decorator is just a closure returning a wrapper over the decorated function.
  fun (x : Int) ↦ _double'wrapper'rn x f

def inc'undecorated := fun (x : Int) ↦ x +ₚ (1 : Int)

attribute [simp, taste_ingr] inc'undecorated

def inc :=
  double inc'undecorated

def inc'undecorated'rn := fun (x : Int) ↦ x +ₚ (1 : Int)

def inc'rn :=
  double'rn inc'undecorated'rn

def value_capture_loop :=
  Id.run
    (do
      -- The CORRECT loop-closure idiom: `n=n` captures BY VALUE, so each closure keeps its own `n` —
      -- which maps naturally to Lean. (Bare `lambda: n` late-binds to the final `n`, a Python footgun.)
      let mut fs := []
      for n in (PastaLean.pyRange (3 : Int))do
        fs :=
          PastaLean.pyAppend fs fun () ↦
            let n := n
            n *ₚ n
      let __py_ret_1 := (PastaLean.pyIter fs).map fun g => g ()
      return __py_ret_1)

attribute [simp, taste_ingr] value_capture_loop

def value_capture_loop'rn :=
  Id.run
    (do
      -- The CORRECT loop-closure idiom: `n=n` captures BY VALUE, so each closure keeps its own `n` —
      -- which maps naturally to Lean. (Bare `lambda: n` late-binds to the final `n`, a Python footgun.)
      let mut fs := []
      for n in (PastaLean.pyRange (3 : Int))do
        fs :=
          PastaLean.pyAppend fs fun () ↦
            let n := n
            n *ₚ n
      let __py_ret_1 := (PastaLean.pyIter fs).map fun g => g ()
      return __py_ret_1)

private def __curry_add'f'g := fun (c : Int) ↦ fun (b : Int) ↦ fun (a : Int) ↦ a +ₚ b +ₚ c

attribute [simp, taste_ingr] __curry_add'f'g

private def _curry_add'f := fun (b : Int) ↦ fun (a : Int) ↦ fun (c : Int) ↦ __curry_add'f'g c b a

attribute [simp, taste_ingr] _curry_add'f

def curry_add := fun (a : Int) ↦
  -- Currying — triple-nested RETURNED closures, each level capturing the one above. Lowers to
  -- nested Lean lambdas over lifted `[simp]` siblings. `curry_add(1)(2)(3) == 6`.
  fun (b : Int) ↦ _curry_add'f b a

attribute [simp, taste_ingr] curry_add

private def __curry_add'f'g'rn := fun (c : Int) ↦ fun (b : Int) ↦ fun (a : Int) ↦ a +ₚ b +ₚ c

private def _curry_add'f'rn := fun (b : Int) ↦ fun (a : Int) ↦ fun (c : Int) ↦ __curry_add'f'g'rn c b a

def curry_add'rn := fun (a : Int) ↦
  -- Currying — triple-nested RETURNED closures, each level capturing the one above. Lowers to
  -- nested Lean lambdas over lifted `[simp]` siblings. `curry_add(1)(2)(3) == 6`.
  fun (b : Int) ↦ _curry_add'f'rn b a

private def _add_one'w := fun (x : Int) ↦ fun (f : Int → Int) ↦ f x +ₚ (1 : Int)

attribute [simp, taste_ingr] _add_one'w

def add_one := fun (f : Int → Int) ↦
  -- A second decorator; stacking `@add_one @double` composes the two wrapper closures.
  fun (x : Int) ↦ _add_one'w x f

attribute [simp, taste_ingr] add_one

private def _add_one'w'rn := fun (x : Int) ↦ fun (f : Int → Int) ↦ f x +ₚ (1 : Int)

def add_one'rn := fun (f : Int → Int) ↦
  -- A second decorator; stacking `@add_one @double` composes the two wrapper closures.
  fun (x : Int) ↦ _add_one'w'rn x f

def stacked'undecorated := fun (x : Int) ↦
  -- `stacked(x)` = add_one(double(identity))(x) = 2*x + 1.
  x

attribute [simp, taste_ingr] stacked'undecorated

def stacked :=
  add_one (double stacked'undecorated)

def stacked'undecorated'rn := fun (x : Int) ↦
  -- `stacked(x)` = add_one(double(identity))(x) = 2*x + 1.
  x

def stacked'rn :=
  add_one'rn (double'rn stacked'undecorated'rn)

private def _multi_capture'poly := fun (x : Int) ↦ fun (a : Int) ↦ fun (b : Int) ↦ fun (c : Int) ↦
  a *ₚ x *ₚ x +ₚ b *ₚ x +ₚ c

attribute [simp, taste_ingr] _multi_capture'poly

def multi_capture := fun (a : Int) ↦ fun (b : Int) ↦ fun (c : Int) ↦
  -- One closure capturing THREE outer variables at once.
  fun (x : Int) ↦ _multi_capture'poly x a b c

attribute [simp, taste_ingr] multi_capture

private def _multi_capture'poly'rn := fun (x : Int) ↦ fun (a : Int) ↦ fun (b : Int) ↦ fun (c : Int) ↦
  a *ₚ x *ₚ x +ₚ b *ₚ x +ₚ c

def multi_capture'rn := fun (a : Int) ↦ fun (b : Int) ↦ fun (c : Int) ↦
  -- One closure capturing THREE outer variables at once.
  fun (x : Int) ↦ _multi_capture'poly'rn x a b c

mutual
  partial def _sibling_closures'lin : Int → Int → Int → Int := fun (x : Int) ↦ fun (a : Int) ↦ fun (b : Int) ↦
    a *ₚ x +ₚ b
  partial def _sibling_closures'apply3 : Int → Int → Int := fun (a : Int) ↦ fun (b : Int) ↦
    _sibling_closures'lin (3 : Int) a b
end

def sibling_closures := fun (a : Int) ↦ fun (b : Int) ↦
  -- `apply3` (a 0-arg closure) CALLS the sibling closure `lin`, and is RETURNED. Calling the returned
  -- 0-arg closure applies it to `Unit`: `sibling_closures(2, 1)() == lin(3) == 2*3 + 1 == 7`.
  fun () ↦ _sibling_closures'apply3 a b

attribute [simp, taste_ingr] sibling_closures

mutual
  partial def _sibling_closures'lin'rn : Int → Int → Int → Int := fun (x : Int) ↦ fun (a : Int) ↦ fun (b : Int) ↦
    a *ₚ x +ₚ b
  partial def _sibling_closures'apply3'rn : Int → Int → Int := fun (a : Int) ↦ fun (b : Int) ↦
    _sibling_closures'lin'rn (3 : Int) a b
end

def sibling_closures'rn := fun (a : Int) ↦ fun (b : Int) ↦
  -- `apply3` (a 0-arg closure) CALLS the sibling closure `lin`, and is RETURNED. Calling the returned
  -- 0-arg closure applies it to `Unit`: `sibling_closures(2, 1)() == lin(3) == 2*3 + 1 == 7`.
  fun () ↦ _sibling_closures'apply3'rn a b

def closure_theorems :=
  -- Properties of the closures above, PROVED automatically on conversion (`--prove-asserts`): each
  -- `assert` becomes a Lean theorem `:= by taste?` and the proof search splices the winning tactic.
  have ht_1 : (make_adder (5 : Int)) (3 : Int) = (8 : Int) := by simp_all (config := { zetaDelta := true }) [taste_ingr]
  have ht_2 : ((curry_add (1 : Int)) (2 : Int)) (3 : Int) = (6 : Int) := by simp_all (config := { zetaDelta := true }) [taste_ingr]
  have ht_3 : (make_adder (2 : Int)) ((make_adder (3 : Int)) (10 : Int)) = (15 : Int) := by simp_all (config := { zetaDelta := true }) [taste_ingr]
  have ht_4 : (multi_capture (1 : Int) (2 : Int) (3 : Int)) (4 : Int) = (27 : Int) := by simp_all (config := { zetaDelta := true }) [taste_ingr]
  have ht_5 : (sibling_closures (2 : Int) (1 : Int)) () = (7 : Int) := by simp_all (config := { zetaDelta := true }) [taste_ingr]; aesop
  ()

attribute [simp] closure_theorems

def closure_theorems'rn :=
  -- Properties of the closures above, PROVED automatically on conversion (`--prove-asserts`): each
  -- `assert` becomes a Lean theorem `:= by taste?` and the proof search splices the winning tactic.
  ()