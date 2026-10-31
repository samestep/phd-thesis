-- The tree Sampson starts from: each node holds its children directly, and
-- the garbage collector frees them, so nothing needs a pool.
data BinOp = Add | Sub | Mul | Div

data Expr = Binary BinOp Expr Expr | Literal Int

interp :: Expr -> Int
interp (Binary op lhs rhs) =
  let l = interp lhs
      r = interp rhs
   in case op of
        Add -> l + r
        Sub -> l - r
        Mul -> l * r
        Div -> if r == 0 then 0 else l `quot` r
interp (Literal num) = num

lit :: Int -> Expr
lit = Literal

bin :: BinOp -> Expr -> Expr -> Expr
bin = Binary

main :: IO ()
main = do
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  print (interp e)
  do
    let f = bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))
    print (interp f)
  print (interp e)
