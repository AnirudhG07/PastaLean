import PastaLean

/-! Unit checks for `type()` / `isinstance()` (`PastaLean.PyAPI.Types`) and `eval()`
(`PastaLean.PyAPI.Builtins.Eval`). -/

namespace PALC.PyAPI.TestTypes
open PastaLean
open TypeInfer (PyType)

/-! ### `type()` — reuses `TypeInfer.PyType`, so classes report as `.cls "Name"` -/
#guard pyType (PyAny.int 5)    == PyType.int
#guard pyType (PyAny.str "a")  == PyType.str
#guard pyType (PyAny.bool true) == PyType.bool
#guard pyType (PyAny.float 1)  == PyType.float
#guard (pyType (PyAny.str "a") == PyType.int) == false
#guard pyType (5 : Int)        == PyType.int
#guard pyType "hi"             == PyType.str
#guard pyType ([1, 2] : List Int) == PyType.list .unknown   -- element-less, like Python's `list`
#guard pyType ((1, 2) : Int × Int) == PyType.tuple []

/-! ### `isinstance()` — with Python's `bool ⊂ int` -/
#guard pyIsInstance (PyAny.int 3) PyType.int
#guard pyIsInstance (PyAny.bool true) PyType.int    -- bool is a subclass of int
#guard (pyIsInstance (PyAny.str "x") PyType.int) == false
#guard pyIsInstance (PyAny.str "x") PyType.str
#guard pyIsInstanceAny (PyAny.str "x") [PyType.int, PyType.str]
#guard (pyIsInstanceAny (PyAny.float 1) [PyType.int, PyType.str]) == false

/-! ### `eval()` — the integer-arithmetic sublanguage, correct precedence -/
#guard pyEval "2+3*4-5"   == 9      -- do_algebra example
#guard pyEval "2*3+4"     == 10
#guard pyEval "2**3*2"    == 16     -- ** above *
#guard pyEval "2+3**2"    == 11     -- ** above +
#guard pyEval "10//3"     == 3      -- floor division
#guard pyEval "(2+3)*4"   == 20     -- parentheses
#guard pyEval "100-2*30"  == 40
#guard pyEval "2 + 3 * 4" == 14     -- whitespace tolerated
#guard pyEval "7%3"       == 1

end PALC.PyAPI.TestTypes
