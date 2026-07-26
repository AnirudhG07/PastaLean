import TypeInfer.PyType
import Mathlib
import Libraries.numpy.Statistics
import Libraries.numpy.LinearAlgebra
import Libraries.numpy.Creation
import Libraries.Behaviour
import Libraries.numpy.NumpyDef

namespace Libraries.numpy

/-- Exact-mode overrides: the constructors, whose field cannot be inferred from an argument, are
`ℚ`-valued so numpy results compose with the surrounding provable code. -/
def pythonNumpyMemberMapExact? (member : String) : Option Lean.Name :=
  match member with
  | "zeros" => some ``pyNumpyZerosRat
  | "ones" => some ``pyNumpyOnesRat
  | "eye" | "identity" => some ``pyNumpyEyeRat
  | _ => none

/-- Library-local registry for NumPy-style helpers. -/
def pythonNumpyMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "array" => some ``pyNumpyArray
  | "asarray" => some ``pyNumpyArray
  | "shape" => some ``pyNumpyShape
  | "empty" => some ``pyNumpyEmpty
  | "full" => some ``pyNumpyFull
  | "arange" => some ``pyNumpyArange
  | "linspace" => some ``pyNumpyLinspace
  | "logspace" => some ``pyNumpyLogspace
  | "meshgrid" => some ``pyNumpyMeshgrid
  | "zeros" => some ``pyNumpyZerosFloat
  | "ones" => some ``pyNumpyOnesFloat
  | "eye" => some ``pyNumpyEyeFloat
  | "identity" => some ``pyNumpyEyeFloat
  | "reshape" => some ``pyNumpyReshape
  | "transpose" => some ``pyNumpyTranspose
  | "expand_dims" => some ``pyNumpyExpandDims
  | "squeeze" => some ``pyNumpySqueeze
  | "concatenate" => some ``pyNumpyConcatenate
  | "vstack" => some ``pyNumpyVstack
  | "hstack" => some ``pyNumpyHstack
  | "split" => some ``pyNumpySplit
  | "tile" => some ``pyNumpyTile
  | "add" => some ``pyNumpyAdd
  | "subtract" => some ``pyNumpySubtract
  | "multiply" => some ``pyNumpyMultiply
  | "scale" => some ``pyNumpyScale
  | "dot" => some ``pyNumpyDot
  | "matmul" => some ``pyNumpyMatmul
  | "min" => some ``pyNumpyMin
  | "max" => some ``pyNumpyMax
  | "argmin" => some ``pyNumpyArgmin
  | "argmax" => some ``pyNumpyArgmax
  | "median" => some ``pyNumpyMedian
  | "sum" => some ``pyNumpySum
  | "mean" => some ``pyNumpyMean
  | "average" => some ``pyNumpyAverage
  | "var" => some ``pyNumpyVar
  | "std" => some ``pyNumpyStd
  | "cov" => some ``pyNumpyCov
  | "corrcoef" => some ``pyNumpyCorrcoef
  | "percentile" => some ``pyNumpyPercentile
  | "ptp" => some ``pyNumpyPtp
  | "prod" => some ``pyNumpyProd
  | "cumsum" => some ``pyNumpyCumsum
  | "cumprod" => some ``pyNumpyCumprod
  | "diff" => some ``pyNumpyDiff
  | "sign" => some ``pyNumpySign
  | "abs" => some ``pyNumpyAbs
  | "absolute" => some ``pyNumpyAbs
  | "maximum" => some ``pyNumpyMaximum
  | "minimum" => some ``pyNumpyMinimum
  | "power" => some ``pyNumpyPower
  | "clip" => some ``pyNumpyClip
  | "round" => some ``pyNumpyRound
  | "exp" => some ``pyNumpyExp
  | "log" => some ``pyNumpyLog
  | "log10" => some ``pyNumpyLog10
  | "log2" => some ``pyNumpyLog2
  | "sqrt" => some ``pyNumpySqrt
  | "norm" => some ``pyNumpyNorm
  | "trace" => some ``pyNumpyTrace
  | "flatten" => some ``pyNumpyFlatten
  | "ravel" => some ``pyNumpyFlatten
  | "any" => some ``pyNumpyAny
  | "all" => some ``pyNumpyAll
  | "isin" => some ``pyNumpyIsin
  | "logical_and" => some ``pyNumpyLogicalAnd
  | "logical_or" => some ``pyNumpyLogicalOr
  | "logical_not" => some ``pyNumpyLogicalNot
  | "isclose" => some ``pyNumpyIsclose
  | "sort" => some ``pyNumpySort
  | "argsort" => some ``pyNumpyArgsort
  | "searchsorted" => some ``pyNumpySearchsorted
  | "unique" => some ``pyNumpyUnique
  | "where" => some ``pyNumpyWhere
  | "nonzero" => some ``pyNumpyNonzero
  | "argwhere" => some ``pyNumpyArgwhere
  | "extract" => some ``pyNumpyExtract
  | "take" => some ``pyNumpyTake
  | "put" => some ``pyNumpyPut
  | "det" => some ``pyNumpyDet
  | "inv" => some ``pyNumpyInv
  | "solve" => some ``pyNumpySolve
  | _ => none

/-- Exact (`ℝ`) versions of the transcendental members, used in the default numeric mode.
`none` for everything else (those keep their regular `pythonNumpyMemberMap?` mapping). -/
def pythonNumpyMemberMapReal? (member : String) : Option Lean.Name :=
  match member with
  | "exp" => some ``pyNumpyExpR
  | "log" => some ``pyNumpyLogR
  | "log10" => some ``pyNumpyLog10R
  | "log2" => some ``pyNumpyLog2R
  | "sqrt" => some ``pyNumpySqrtR
  | "std" => some ``pyNumpyStdR
  | _ => none

/-- Peel a nested list to its scalar element (`List (List ℚ)` → `ℚ`). -/
partial def scalarField : TypeInfer.PyType → TypeInfer.PyType
  | .list e => scalarField e
  | t => t

/-- numpy member behaviour — the return type as a function of the FIRST argument's type, since the
shims are polymorphic over the field (`np.dot` of `ℚ` vectors gives `ℚ`). `none` = let Lean infer it.
Reductions/elementwise/creators always return `Float` (never the caller's `ℚ`), so they are omitted
and left for Lean to infer — forcing `ℚ` in exact mode would clash with the shim. -/
def numpyBehaviour? (member : String) : Option Libraries.Behaviour :=
  let ofArg0 (f : TypeInfer.PyType → TypeInfer.PyType) : Libraries.Behaviour :=
    { returns := fun as => f ((as[0]?).getD .unknown) }
  -- `dot` is the one field-scalar reduction (`… → γ`): result = the arg's scalar field.
  if member == "dot" then some (ofArg0 scalarField)
  -- Field-preserving matrix ops (`… → List (List α)`): result has the arg's shape and field.
  else if ["add", "subtract", "multiply", "scale", "matmul"].contains member then some (ofArg0 id)
  else if ["argmax", "argmin", "searchsorted"].contains member then some (ofArg0 fun _ => .int)
  else if ["argsort", "nonzero", "shape"].contains member then some (ofArg0 fun _ => .list .int)
  else if ["any", "all"].contains member then some (ofArg0 fun _ => .bool)
  else none

end Libraries.numpy
