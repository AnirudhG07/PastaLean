import PastaLean.Imports

namespace Libraries.hashlib

/-! Python's `hashlib` — **stand-in only**.

`pyMd5HexdigestDummy` is NOT MD5. It is a deterministic 128-bit FNV-1a-style digest rendered as 32
lowercase hex characters, so the *shape* of the value is right (length, alphabet, determinism,
avalanche on small edits) and downstream code keeps type-checking and running. The digits are wrong.

The `Dummy` suffix is load-bearing: `PastaLean.Linter.markerLinter` flags every use site with a
yellow warning (`linter.dummyImplementation`), so no caller can silently believe it hashed anything.

Implementing real MD5 is a self-contained ~150-line job (padding, the 64-round compression, the
`UInt32` tables) — there is no MD5 anywhere in the Lean toolchain, Batteries or Mathlib to reuse.
-/

/-- 2^64, so the lanes stay in range without `UInt64` wraparound reasoning. -/
private def modulus : Nat := 18446744073709551616

/-- One FNV-1a-ish absorb step. -/
private def absorb (h : Nat) (b : Nat) : Nat := ((h ^^^ b) * 1099511628211) % modulus

/-- Render `n` as exactly `width` lowercase hex digits (truncating from the right). -/
private def toHexPadded (n : Nat) (width : Nat) : String :=
  let digits := (Nat.toDigits 16 n).map Char.toLower
  let n := digits.length
  if n ≥ width then String.ofList (digits.drop (n - width))
  else String.ofList (List.replicate (width - n) '0' ++ digits)

/-- **DUMMY** `hashlib.md5(s).hexdigest()`: a deterministic 32-hex-character digest that is NOT
MD5. Two lanes with different seeds give the 128 bits' worth of output width. -/
def pyMd5HexdigestDummy (s : String) : String :=
  let bytes := s.toList.map Char.toNat
  let lane₁ := bytes.foldl absorb 14695981039346656037
  let lane₂ := bytes.reverse.foldl absorb 1099511628211
  toHexPadded lane₁ 16 ++ toHexPadded lane₂ 16

/-- **DUMMY** `hashlib.md5()` / `hashlib.md5(s)`. The hash object is modelled as the accumulated
message: construction carries the (possibly empty) seed, `update` appends, `hexdigest` digests. -/
def pyMd5Dummy (s : String := "") : String := s

/-- **DUMMY** `h.update(chunk)`: append to the accumulated message. Python mutates the object in
place, so codegen rebinds the receiver (`h := pyHashUpdateDummy h chunk`). -/
def pyHashUpdateDummy (acc chunk : String) : String := acc ++ chunk

/-- **DUMMY** `hashlib.sha256(s).hexdigest()`: same stand-in, widened to 64 hex characters. -/
def pySha256HexdigestDummy (s : String) : String :=
  let d := pyMd5HexdigestDummy s
  d ++ pyMd5HexdigestDummy d

end Libraries.hashlib
