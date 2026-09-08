import Libraries.hashlib.HashlibDef
import Libraries.Behaviour

namespace Libraries.hashlib
open Libraries

/-- Map supported `hashlib` members. `md5` is REAL; `sha256` is a stand-in (`*Dummy`, flagged by
`linter.dummyImplementation` at each use site). -/
def pythonHashlibMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "md5"    => some ``Libraries.hashlib.pyMd5
  | "sha256" => some ``Libraries.hashlib.pySha256HexdigestDummy
  | _ => none

-- `hashlibBehaviour?` (type-inference return shapes) moved to `Libraries/TypeBehaviour.lean`.

/-- Methods on a hashlib object (a value produced by `md5`/`sha256`). -/
def hashlibMethod? (member : String) : Option Lean.Name :=
  match member with
  | "update"              => some ``Libraries.hashlib.pyHashUpdate
  | "hexdigest" | "digest" => some ``Libraries.hashlib.pyMd5Hexdigest
  | _ => none

end Libraries.hashlib
