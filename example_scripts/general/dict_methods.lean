import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

def dict_views :=
  let d := (Std.HashMap.ofList [("a", (1 : Int)), ("b", (2 : Int)), ("c", (3 : Int))] : Std.HashMap String Int)
  let its := (PastaLean.pyItems d : List (String × Int))
  let ks := (PastaLean.pyKeys d : List String)
  let vs := (PastaLean.pyAnys d : List Int)
  (its, (ks, vs))

attribute [simp, taste_ingr] dict_views

def dict_views'rn :=
  let d := (Std.HashMap.ofList [("a", (1 : Int)), ("b", (2 : Int)), ("c", (3 : Int))] : Std.HashMap String Int)
  let its := (PastaLean.pyItems d : List (String × Int))
  let ks := (PastaLean.pyKeys d : List String)
  let vs := (PastaLean.pyAnys d : List Int)
  (its, (ks, vs))

def dict_len :=
  let d := (Std.HashMap.ofList [("x", (10 : Int)), ("y", (20 : Int))] : Std.HashMap String Int)
  PastaLean.pyLen d

attribute [simp, taste_ingr] dict_len

def dict_len'rn :=
  let d := (Std.HashMap.ofList [("x", (10 : Int)), ("y", (20 : Int))] : Std.HashMap String Int)
  PastaLean.pyLen d