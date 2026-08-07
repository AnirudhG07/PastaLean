import Libraries.hashlib.HashlibDef
import Libraries.Behaviour

namespace Libraries.hashlib
open Libraries

/-- Map supported `hashlib` members. Every one is a **stand-in** (`*Dummy`), so the
`linter.dummyImplementation` marker linter warns at each use site. -/
def pythonHashlibMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "md5"    => some ``Libraries.hashlib.pyMd5Dummy
  | "sha256" => some ``Libraries.hashlib.pySha256HexdigestDummy
  | _ => none

/-- `md5(...)` carries the message through and `hexdigest()` digests it, so both are `str`. The
constructors also declare `constructsObject`, so `m = hashlib.md5()` makes `m.update(...)` dispatch
here instead of to the dict/set `update`. -/
def hashlibBehaviour? (member : String) : Option Behaviour :=
  open Behaviour in
  match member with
  | "md5" | "sha256" => some { const .str with constructsObject := true }
  | "hexdigest" | "digest" | "update" => some (const .str)
  | _ => none

/-- Methods on a hashlib object (a value produced by `md5`/`sha256`). -/
def hashlibMethod? (member : String) : Option Lean.Name :=
  match member with
  | "update"              => some ``Libraries.hashlib.pyHashUpdateDummy
  | "hexdigest" | "digest" => some ``Libraries.hashlib.pyMd5HexdigestDummy
  | _ => none

end Libraries.hashlib
