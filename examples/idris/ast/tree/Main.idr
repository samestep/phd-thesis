-- The tree Sampson starts from: each node holds its children directly as
-- garbage-collected values, so nothing needs a pool or an `IO` to build.
data BinOp = Add | Sub | Mul | Div

data Expr = Binary BinOp Expr Expr | Literal Integer

-- Idris's `div` rounds down; the post's division truncates toward zero.
quot : Integer -> Integer -> Integer
quot l r = let q = abs l `div` abs r in if (l < 0) /= (r < 0) then negate q else q

interp : Expr -> Integer
interp (Binary op lhs rhs) =
  let l = interp lhs
      r = interp rhs
  in case op of
    Add => l + r
    Sub => l - r
    Mul => l * r
    Div => if r == 0 then 0 else quot l r
interp (Literal num) = num

lit : Integer -> Expr
lit = Literal

bin : BinOp -> Expr -> Expr -> Expr
bin = Binary

main : IO ()
main = do
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  printLn (interp e)
  do
    let f = bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))
    printLn (interp f)
  printLn (interp e)
