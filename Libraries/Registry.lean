import Lean
import Libraries.Mutator
import Libraries.Behaviour
import Libraries.bisect.Mapping
import Libraries.collections.Mapping
import Libraries.functools.Mapping
import Libraries.heapq.Mapping
import Libraries.itertools.Mapping
import Libraries.math.Mapping
import Libraries.operator.Mapping
import Libraries.string.Mapping
import Libraries.numpy.Mapping
import Libraries.passta.Mapping
import Libraries.scipy.Mapping
import Libraries.pandas.Mapping
import Libraries.sortedcontainers.Mapping

namespace Libraries

/--
Registry mapping imported Python library members to Lean runtime functions/constants.

This plays the same role for imported libraries that `PastaLean.Attributes` plays for
Python methods: codegen consults this table once an AST node has been recognized as
coming from a specific imported module.
-/
def pythonLibraryMap? (moduleName member : String) : Option Lean.Name :=
  match moduleName with
  | "bisect" => bisect.pythonBisectMemberMap? member
  | "collections" => collections.pythonCollectionsMemberMap? member
  | "functools" => functools.pythonFunctoolsMemberMap? member
  | "heapq" => heapq.pythonHeapqMemberMap? member
  | "itertools" => itertools.pythonItertoolsMemberMap? member
  | "math" => math.pythonMathMemberMap? member
  | "operator" => operator.pythonOperatorMemberMap? member
  | "string" => string.pythonStringMemberMap? member
  | "numpy" => numpy.pythonNumpyMemberMap? member
  | "passta" => passta.pythonPasstaMemberMap? member
  | "scipy" => scipy.pythonScipyMemberMap? member
  | "pandas" => pandas.pythonPandasMemberMap? member
  | "sortedcontainers" => sortedcontainers.pythonSortedcontainersMemberMap? member
  | _ => none

/--
Exact-mode (`ℝ`, `noncomputable`) registry for transcendental library members.

In the default numeric mode codegen consults this first; a hit lowers `math.exp` etc. to the
`Real.*`-backed version (provable, not runnable). A miss falls back to `pythonLibraryMap?` (the
regular, often `Float`-valued, mapping) — so non-transcendental members are unaffected.
-/
def pythonLibraryMapReal? (moduleName member : String) : Option Lean.Name :=
  match moduleName with
  | "math" => math.pythonMathMemberMapReal? member
  | "numpy" => numpy.pythonNumpyMemberMapReal? member
  | "scipy" => scipy.pythonScipyMemberMapReal? member
  | _ => none

/-- Exact-mode overrides that are computable + provable but NOT transcendental `ℝ` (e.g.
`math.pow` with an integer exponent → rational power). Consulted in exact mode after the real map
and before the regular (`Float`) map. -/
def pythonLibraryMapExact? (moduleName member : String) : Option Lean.Name :=
  match moduleName with
  | "math" => math.pythonMathMemberMapExact? member
  | "numpy" => numpy.pythonNumpyMemberMapExact? member
  | _ => none

/-- The `Behaviour` of a **qualified** library member `module.member` — the single record carrying
its return shape, mutation, and iterator kind. Adding a library member is one entry in that library's
own `Mapping.lean`; this dispatch and the derived views below never change. -/
def memberBehaviour? (moduleName member : String) : Option Behaviour :=
  match moduleName with
  | "heapq"       => heapq.heapqBehaviour? member
  | "itertools"   => itertools.itertoolsBehaviour? member
  | "collections" => collections.collectionsBehaviour? member
  | "bisect"      => bisect.bisectBehaviour? member
  | "math"        => math.mathBehaviour? member
  | "scipy"       => scipy.scipyBehaviour? member
  | "numpy"       => numpy.numpyBehaviour? member
  | "sortedcontainers" => sortedcontainers.sortedcontainersBehaviour? member
  | _ => none

/-- The `Behaviour` of a BARE callable name (a builtin, or a star-imported library member) — the entry
point TypeInfer consults for a `Name` call. Excludes `math`/`scipy`/`numpy`, which are qualified-only,
so a user function named `pow`/`sqrt`/`dot` is not shadowed by the library. -/
def bareBehaviour? (name : String) : Option Behaviour :=
  (builtinBehaviour? name).orElse fun _ =>
  (itertools.itertoolsBehaviour? name).orElse fun _ =>
  (heapq.heapqBehaviour? name).orElse fun _ =>
  (collections.collectionsBehaviour? name).orElse fun _ =>
  (bisect.bisectBehaviour? name)

/-! ### Views derived from `memberBehaviour?` — one field each, so existing call sites are unchanged. -/

/-- Return type of a qualified library member, for TypeInfer (`.unknown` → `none`, as before). -/
def libraryMemberReturn? (moduleName member : String) (arg0 : TypeInfer.PyType) :
    Option TypeInfer.PyType :=
  match (memberBehaviour? moduleName member).map (·.returns [arg0]) with
  | some t => if t == .unknown then none else some t
  | none => none

/-- The in-place mutation spec of a library member, for the core codegen. -/
def libraryMutator? (moduleName member : String) : Option LibraryMutator :=
  (memberBehaviour? moduleName member).bind (·.mutator)

/-- The unbounded-iterator spec of a library member, for the core codegen. -/
def libraryInfiniteIter? (moduleName member : String) : Option InfiniteIter :=
  (memberBehaviour? moduleName member).bind (·.infiniteIter)

/-- A method that a library declares as a no-op, for the core codegen — keyed on the method name
alone (these come from decorated values, e.g. `f.cache_clear()`, which carry no module tag). One
entry point, so codegen names no specific library. -/
def libraryNoopMethod? (member : String) : Option Lean.Name :=
  functools.functoolsNoopMethod? member

/-- A decorator a library declares transparent — no effect on the transpiled value, so the decorated
function is emitted unchanged (e.g. functools' `@cache`). One entry point, so codegen names no
specific library. The caller passes the decorator's last dotted segment (`functools.cache` → `cache`). -/
def libraryTransparentDecorator? (name : String) : Bool :=
  functools.functoolsTransparentDecorator? name

end Libraries
