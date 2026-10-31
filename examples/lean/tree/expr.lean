-- The tree Sampson starts from: each node holds its children directly as
-- reference-counted values, so nothing needs a pool and `interp` is structural.
inductive BinOp where
  | add | sub | mul | div

inductive Expr where
  | binary (op : BinOp) (lhs rhs : Expr)
  | literal (num : Int)

def interp : Expr → Int
  | .binary op lhs rhs =>
    let l := interp lhs
    let r := interp rhs
    match op with
    | .add => l + r
    | .sub => l - r
    | .mul => l * r
    | .div => if r == 0 then 0 else l.tdiv r
  | .literal num => num

def lit (n : Int) : Expr := .literal n
def bin (op : BinOp) (l r : Expr) : Expr := .binary op l r

def main : IO Unit := do
  let e := bin .div (bin .mul (bin .sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  IO.println (interp e)
  do
    let f := bin .div (bin .add (lit 4) (lit 4)) (bin .sub (lit 4) (lit 4))
    IO.println (interp f)
  IO.println (interp e)
