namespace multiple_returns

class Length (α : Type) where
  length : α → Nat

instance : Length (List α) where
  length := List.length

instance : Length (String) where
  length := String.length

def length [Length α] (x : α) : Nat :=
  Length.length x

def funWithLengthType (x : Nat) : Type :=
  match x with
  | 0 => String
  | _ + 1 => List Nat

instance  : Length (funWithLengthType n) where
  length x := match n with
    | 0 => String.length x
    | _ + 1 => List.length x


def funWithLength
  (x : Nat) : funWithLengthType x :=
  match x with
  | 0 => "zero"
  | n + 1 => List.range (n + 1)

def lengthOfFunWithLength
  (n : Nat) : Nat :=
  let x : funWithLengthType n := funWithLength n
  length x


#eval lengthOfFunWithLength 0 -- 4
#eval lengthOfFunWithLength 5 -- 5

end multiple_returns
