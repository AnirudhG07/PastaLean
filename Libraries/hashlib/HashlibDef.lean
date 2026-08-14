import PastaLean.Imports

namespace Libraries.hashlib

/-! Python's `hashlib`.

`md5` is a **real** implementation of RFC 1321 (padding, the 64-round compression over the
`UInt32` sine table, little-endian output), so `hashlib.md5(s).hexdigest()` matches CPython.
`sha256` remains a stand-in (`*Dummy`, flagged by `linter.dummyImplementation`).
-/

/-! ### Real MD5 (RFC 1321) -/

/-- Per-round constants `K[i] = ⌊2³² · |sin(i+1)|⌋`. -/
private def md5K : Array UInt32 := #[
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391]

/-- Per-round left-rotation amounts. -/
private def md5S : Array UInt32 := #[
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]

private def rotl32 (x : UInt32) (c : UInt32) : UInt32 := (x <<< c) ||| (x >>> (32 - c))

/-- Little-endian 32-bit word from `msg[off..off+3]`. -/
private def le32 (msg : ByteArray) (off : Nat) : UInt32 :=
  (msg.get! off).toUInt32 ||| ((msg.get! (off + 1)).toUInt32 <<< 8) |||
    ((msg.get! (off + 2)).toUInt32 <<< 16) ||| ((msg.get! (off + 3)).toUInt32 <<< 24)

/-- Compress one 64-byte block at `off` into the running state `(a,b,c,d)`. -/
private def md5Block (msg : ByteArray) (off : Nat) (a0 b0 c0 d0 : UInt32) :
    UInt32 × UInt32 × UInt32 × UInt32 := Id.run do
  let mut A := a0; let mut B := b0; let mut C := c0; let mut D := d0
  for i in [0:64] do
    let (f, g) :=
      if i < 16 then ((B &&& C) ||| ((~~~B) &&& D), i)
      else if i < 32 then ((D &&& B) ||| ((~~~D) &&& C), (5 * i + 1) % 16)
      else if i < 48 then (B ^^^ C ^^^ D, (3 * i + 5) % 16)
      else (C ^^^ (B ||| (~~~D)), (7 * i) % 16)
    let f := f + A + md5K[i]! + le32 msg (off + 4 * g)
    A := D; D := C; C := B
    B := B + rotl32 f md5S[i]!
  return (a0 + A, b0 + B, c0 + C, d0 + D)

private def hexDigit (n : UInt8) : Char :=
  let n := n.toNat
  Char.ofNat (if n < 10 then n + '0'.toNat else n - 10 + 'a'.toNat)

/-- A byte as two lowercase hex digits. -/
private def hex8 (b : UInt8) : String := String.ofList [hexDigit (b >>> 4), hexDigit (b &&& 0xf)]

/-- A 32-bit word as 8 lowercase hex digits in LITTLE-endian byte order (MD5's output order). -/
private def hex32le (w : UInt32) : String := Id.run do
  let mut s := ""
  for j in [0:4] do
    s := s ++ hex8 ((w >>> (8 * j.toUInt32)) &&& 0xff).toUInt8
  return s

/-- Real MD5 digest of a byte string, as 32 lowercase hex characters (RFC 1321). -/
def md5HexBytes (input : ByteArray) : String := Id.run do
  let ml := input.size
  -- Pad: append 0x80, then 0x00 until length ≡ 56 (mod 64), then the 64-bit little-endian bit length.
  let mut padded := input.push 0x80
  while padded.size % 64 != 56 do
    padded := padded.push 0
  let bits : UInt64 := ml.toUInt64 * 8
  for j in [0:8] do
    padded := padded.push (bits >>> (8 * j.toUInt64)).toUInt8
  -- Compress every block.
  let mut a : UInt32 := 0x67452301; let mut b : UInt32 := 0xefcdab89
  let mut c : UInt32 := 0x98badcfe; let mut d : UInt32 := 0x10325476
  for blk in [0:padded.size / 64] do
    let (na, nb, nc, nd) := md5Block padded (blk * 64) a b c d
    a := na; b := nb; c := nc; d := nd
  return hex32le a ++ hex32le b ++ hex32le c ++ hex32le d

/-! ### The `hashlib` object model

`m = hashlib.md5()` carries the accumulated message (a `String`); `m.update(chunk)` appends;
`m.hexdigest()` runs the real MD5 over the message's UTF-8 bytes (matching `text.encode("utf-8")`).
-/

/-- `hashlib.md5()` / `hashlib.md5(s)` — the hash object, modelled as its accumulated message. -/
def pyMd5 (s : String := "") : String := s

/-- `h.update(chunk)`: append to the accumulated message (Python mutates in place; codegen rebinds). -/
def pyHashUpdate (acc chunk : String) : String := acc ++ chunk

/-- `hashlib.md5(s).hexdigest()` — the REAL MD5 of `s`'s UTF-8 encoding. -/
def pyMd5Hexdigest (s : String) : String := md5HexBytes s.toUTF8

/-! ### `sha256` — still a stand-in -/

/-- 2^64, so the FNV lanes stay in range. -/
private def modulus : Nat := 18446744073709551616
private def absorb (h : Nat) (b : Nat) : Nat := ((h ^^^ b) * 1099511628211) % modulus
private def toHexPadded (n : Nat) (width : Nat) : String :=
  let digits := (Nat.toDigits 16 n).map Char.toLower
  let k := digits.length
  if k ≥ width then String.ofList (digits.drop (k - width))
  else String.ofList (List.replicate (width - k) '0' ++ digits)

/-- **DUMMY** `hashlib.sha256(s).hexdigest()`: an FNV-1a stand-in widened to 64 hex chars, NOT SHA-256. -/
def pySha256HexdigestDummy (s : String) : String :=
  let bytes := s.toList.map Char.toNat
  let lane₁ := bytes.foldl absorb 14695981039346656037
  let lane₂ := bytes.reverse.foldl absorb 1099511628211
  let d := toHexPadded lane₁ 16 ++ toHexPadded lane₂ 16
  d ++ toHexPadded (bytes.foldl absorb 1) 16 ++ toHexPadded (bytes.reverse.foldl absorb 2) 16

end Libraries.hashlib
