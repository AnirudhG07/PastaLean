import TypeInfer.PyType
import Libraries.Mutator

/-!
# Member behaviour: one self-describing record per Python callable

`pythonLibraryMap?` says *which Lean function* a Python member maps to. That is only half the story:
the transpiler also needs the **translation-relevant behaviour** a name→function map can't express —

* what type it *returns*, as a function of its argument types (so a binder can be typed by the join
  of its writes — see `docs/design-choices.md` §27), and
* whether it *teaches* one of its arguments a new element type by mutating it in place (`heappush(h,
  x)` makes `h` hold `x`), which drives the same widening chain.

Historically these lived as scattered `match name with …` arms inside `TypeInfer/Rules.lean` — so
adding a library, or a new builtin, meant editing the inference engine. `Behaviour` moves that
knowledge next to the mapping, where a library **self-describes**; each member is written as a named
return-*shape* combinator (`listOf 0`, `listOfTuples`, `push 0 1`), not a raw lambda.
-/

namespace Libraries
open TypeInfer

/-- The behaviour of one Python callable beyond "it maps to Lean function F". Every field has a
"no information" default, so a member only declares what is non-trivial about it. -/
structure Behaviour where
  /-- Result type as a function of the argument types. `.unknown` = "let inference infer it". -/
  returns  : List PyType → PyType := fun _ => .unknown
  /-- `some (container, element)`: calling this makes argument `container` hold, as its element type,
  the type of argument `element` — the inference side of an in-place mutation (`heappush(h, x)` →
  `(0, 1)`). Feeds the numeric/element widening chain. -/
  teaches? : Option (Nat × Nat) := none

namespace Behaviour

/-- The `i`-th argument type, `.unknown` past the end. -/
private def arg (as : List PyType) (i : Nat) : PyType := (as[i]?).getD .unknown

/-! ### Return-shape combinators — a member declares its behaviour as a named shape, not a lambda. -/

/-- Always the fixed type `t` (`range` → `List Int`). -/
def const (t : PyType) : Behaviour := { returns := fun _ => t }
/-- The element type of argument `i` (`heappop(h)` returns `h`'s element). -/
def elementOf (i : Nat) : Behaviour := { returns := fun as => (arg as i).elemType }
/-- `List` of argument `i`'s element type (`sorted`, `list`, `deque`, `accumulate`). -/
def listOf (i : Nat) : Behaviour := { returns := fun as => .list (arg as i).elemType }
/-- `Set` of argument `i`'s element type (`set`, `frozenset`). -/
def setOf (i : Nat) : Behaviour := { returns := fun as => .set (arg as i).elemType }
/-- Argument `i`'s own type, unchanged (`dict(d)`, `OrderedDict(d)`, `abs(x)`). -/
def argType (i : Nat) : Behaviour := { returns := fun as => arg as i }
/-- `dict[element of arg i, int]` — a counting map (`Counter(xs)`). -/
def counterOf (i : Nat) : Behaviour := { returns := fun as => .dict (arg as i).elemType .int }
/-- `List` of tuples pairing every argument's element type (`zip`, `product`). -/
def listOfTuples : Behaviour := { returns := fun as => .list (.tuple (as.map (·.elemType))) }
/-- `List` of the arguments' common (joined) element type (`chain`). -/
def listOfJoined : Behaviour := { returns := fun as => .list (PyType.joinAll (as.map (·.elemType))) }
/-- `List (int, element of arg 0)` (`enumerate(xs)`). -/
def enumerated : Behaviour := { returns := fun as => .list (.tuple [.int, (arg as 0).elemType]) }
/-- `List (elem, elem)` of consecutive pairs (`pairwise(xs)`). -/
def adjacentPairs : Behaviour := { returns := fun as => let e := (arg as 0).elemType; .list (.tuple [e, e]) }
/-- One container argument → its element type; several arguments → their join (`min`, `max`). -/
def elementOrJoin : Behaviour := { returns := fun as => match as with
                                    | [x] => x.containerElemOrSelf | _ => PyType.joinAll as }
/-- One container argument → its element type; several arguments → the first (`sum`). -/
def elementOrFirst : Behaviour := { returns := fun as => match as with
                                    | [x] => x.containerElemOrSelf | _ => arg as 0 }
/-- A push-family mutation: argument `container` gains argument `element`'s type as its element
(`heappush(h, x)` → `push 0 1`), driving the widening chain. -/
def push (container element : Nat) : Behaviour := { teaches? := some (container, element) }

end Behaviour

/-- Behaviour of a Python **builtin** whose result depends on its arguments (`zip`, `min`, `range`).
Builtins with a fixed constant result stay in `constReturnBuiltins`; each *library's* members are
declared in that library's own `Mapping.lean` and aggregated by `Registry.bareBehaviour?`. -/
def builtinBehaviour? (name : String) : Option Behaviour :=
  open Behaviour in
  match name with
  | "range"                        => some (const (.list .int))
  | "list" | "sorted" | "reversed" => some (listOf 0)
  | "set" | "frozenset"            => some (setOf 0)
  | "tuple"                        => some (listOf 0)
  | "dict" | "abs"                 => some (argType 0)
  | "zip"                          => some listOfTuples
  | "enumerate"                    => some enumerated
  | "min" | "max"                  => some elementOrJoin
  | "sum"                          => some elementOrFirst
  | _                              => none

end Libraries
