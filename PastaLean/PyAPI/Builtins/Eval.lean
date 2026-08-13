import PastaLean.Imports

/-!
# `eval()` — a runtime arithmetic-expression evaluator

Python's `eval` on a runtime-built *string* (e.g. `do_algebra` assembles `"2+3*4-5"`) cannot use Lean's
elaboration-time `evalExpr` (the `py_term%` macro path) — that needs the compiler environment, which a
compiled/`lean --run` twin does not carry. Instead this is a total, pure recursive-descent evaluator
over the integer-arithmetic sublanguage Python `eval` is actually used for in this corpus:

  `**` (right-assoc, highest) > unary `+`/`-` > `* // / %` (left) > `+ -` (left), with parentheses.

Malformed input yields `0` rather than raising (a twin returns a value; it never needs to trap).
-/

namespace PastaLean

private abbrev Toks := List Char

private def skipWs (cs : Toks) : Toks := cs.dropWhile (· == ' ')

private partial def readInt (cs : Toks) : Int × Toks :=
  let ds := cs.takeWhile Char.isDigit
  let rest := cs.dropWhile Char.isDigit
  (((String.ofList ds).toInt?).getD 0, rest)

mutual
  /-- `expr := term (('+' | '-') term)*` -/
  private partial def pExpr (cs : Toks) : Int × Toks :=
    let (v, r) := pTerm cs
    pAdd v r
  private partial def pAdd (acc : Int) (cs : Toks) : Int × Toks :=
    match skipWs cs with
    | '+' :: r => let (v, r') := pTerm r; pAdd (acc + v) r'
    | '-' :: r => let (v, r') := pTerm r; pAdd (acc - v) r'
    | r => (acc, r)
  /-- `term := pow (('*' | '//' | '/' | '%') pow)*` -/
  private partial def pTerm (cs : Toks) : Int × Toks :=
    let (v, r) := pPow cs
    pMul v r
  private partial def pMul (acc : Int) (cs : Toks) : Int × Toks :=
    match skipWs cs with
    | '/' :: '/' :: r => let (v, r') := pPow r; pMul (Int.fdiv acc v) r'
    | '*' :: r        => let (v, r') := pPow r; pMul (acc * v) r'
    | '/' :: r        => let (v, r') := pPow r; pMul (Int.fdiv acc v) r'
    | '%' :: r        => let (v, r') := pPow r; pMul (Int.fmod acc v) r'
    | r => (acc, r)
  /-- `pow := atom ('**' pow)?`  — right-associative, above the multiplicatives. -/
  private partial def pPow (cs : Toks) : Int × Toks :=
    let (base, r) := pAtom cs
    match skipWs r with
    | '*' :: '*' :: r2 => let (e, r3) := pPow r2; (base ^ e.toNat, r3)
    | r2 => (base, r2)
  /-- `atom := number | '(' expr ')' | ('+' | '-') atom` -/
  private partial def pAtom (cs : Toks) : Int × Toks :=
    match skipWs cs with
    | '(' :: r =>
        let (v, r') := pExpr r
        match skipWs r' with
        | ')' :: r'' => (v, r'')
        | r'' => (v, r'')
    | '-' :: r => let (v, r') := pAtom r; (-v, r')
    | '+' :: r => pAtom r
    | cs' => readInt cs'
end

/-- `eval(s)` over the integer-arithmetic sublanguage (`+ - * / // % **`, parens). -/
def pyEval (s : String) : Int := (pExpr s.toList).1

end PastaLean
