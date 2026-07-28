import Mathlib
import PastaLean.PyAPI

namespace PastaLean

/--
Registry mapping Python-style method names to their Lean runtime implementations.

The runtime functions themselves live under `PastaLean/PyAPI/*`; this file keeps the
codegen-facing dispatch table in one place.

Only Python methods belong here. Builtins and operators that lower to CommonProtocols
functions like `pyLen` or `pyContains` should be wired through builtin/operator
lowering instead of this table.
-/
def pythonMethodMap? (attr : String) : Option Lean.Name :=
  match attr with
  -- String Only
  | "split"      => some ``pyStringSplit
  | "splitlines" => some ``pyStringSplitlines
  | "join"       => some ``pyStringJoin
  | "replace"    => some ``pyStringReplace
  | "strip"      => some ``pyStringStrip
  | "lstrip"     => some ``pyStringLstrip
  | "rstrip"     => some ``pyStringRstrip
  | "rfind"      => some ``pyStringRfind
  | "zfill"      => some ``pyStringZfill
  | "startswith" => some ``pyStringStartswith
  | "endswith"   => some ``pyStringEndswith
  | "lower"      => some ``pyStringLower
  | "upper"      => some ``pyStringUpper
  | "islower"    => some ``pyIsLower
  | "isupper"    => some ``pyIsUpper
  | "isalpha"    => some ``pyIsAlpha
  -- `isdigit`/`isnumeric`/`isdecimal` coincide on ASCII digits.
  | "isdecimal"  => some ``pyIsDecimal
  | "isdigit"    => some ``pyIsDecimal
  | "isnumeric"  => some ``pyIsDecimal
  | "isalphanum" => some ``pyIsAlphanum
  | "isalnum"    => some ``pyIsAlphanum
  | "isspace"    => some ``pyIsWhitespace
  | "partition"  => some ``pyPartition
  | "capitalize" => some ``pyStringCapitalize
  | "title"        => some ``pyStringTitle
  | "swapcase"     => some ``pyStringSwapcase
  | "casefold"     => some ``pyStringCasefold
  | "removeprefix" => some ``pyStringRemovePrefix
  | "removesuffix" => some ``pyStringRemoveSuffix
  | "rjust"        => some ``pyStringRjust
  | "ljust"        => some ``pyStringLjust
  | "center"       => some ``pyStringCenter
  -- List Only
  | "append"     => some ``pyAppend
  | "appendleft" => some ``pyAppendLeft
  | "extend"     => some ``pyExtend
  | "reverse"    => some ``pyReverse
  | "copy"       => some ``pyCopy
  -- Set Only (pure, non-mutating — return a new set / Bool; the `&`/`|`/`-`/`^` operators lower
  -- to the same runtime functions).
  | "union"                => some ``pySetUnion
  | "intersection"         => some ``pySetIntersection
  | "difference"           => some ``pySetDifference
  | "symmetric_difference" => some ``pySetSymmetricDifference
  | "issubset"             => some ``pySetSubset
  | "issuperset"           => some ``pySetSuperset
  | "isdisjoint"           => some ``pySetIsDisjoint
  -- Dict Only
  | "items"      => some ``pyItems
  | "keys"       => some ``pyKeys
  | "values"     => some ``pyAnys
  -- Counter (a `Libraries.collections.PyDefaultDict`). Single-backtick Name literals: the runtime
  -- lives in `Libraries`, which `PastaLean` cannot import, but the generated file `open`s it.
  | "most_common" => some `Libraries.collections.pyMostCommon
  | "elements"    => some `Libraries.collections.pyElements
  -- Int only
  | "bit_length" => some ``pyBitLength
  | "bit_count"  => some ``pyBitCount
  -- Dunder methods
  | "__len__"    => some ``pyLen
  -- Common
  | "clear"      => some ``pyClear
  | "update"     => some ``pyUpdate
  | "pop"        => some ``pyPop
  | "count"      => some ``pyCount
  | "find"        => some ``pyStringFind
  | "index"      => some ``pyIndex
  | _            => none

/--
Backward-compatible alias used by older codegen paths.

The `?`-suffixed version is the canonical name because lookup may fail, but keeping
this alias avoids churn in generators that still call `pythonMethodMap`.
-/
def pythonMethodMap (attr : String) : Option Lean.Name :=
  pythonMethodMap? attr

end PastaLean
