-- Named implementations: two `ExprPool` implementations, picked by name with `@{...}`.
import Data.IORef
import Data.List
import Data.Maybe

data BinOp = Add | Sub | Mul | Div

record ExprRef where
  constructor MkExprRef
  index : Nat

data Expr = Binary BinOp ExprRef ExprRef | Literal Integer

-- Idris's `div` rounds down; the post's division truncates toward zero.
quot : Integer -> Integer -> Integer
quot l r = let q = abs l `div` abs r in if (l < 0) /= (r < 0) then negate q else q

interface ExprPool where
  exprs : IORef (List Expr)

add : ExprPool => Expr -> IO ExprRef
add expr = do
  modifyIORef exprs (++ [expr])
  pure (MkExprRef (length !(readIORef exprs) `minus` 1))

get : ExprPool => ExprRef -> IO Expr
get expr = pure (fromMaybe (Literal 0) (getAt expr.index !(readIORef exprs)))

interp : ExprPool => ExprRef -> IO Integer
interp expr = case !(get expr) of
  Binary op lhs rhs => do
    l <- interp lhs
    r <- interp rhs
    pure $ case op of
      Add => l + r
      Sub => l - r
      Mul => l * r
      Div => if r == 0 then 0 else quot l r
  Literal num => pure num

lit : ExprPool => Integer -> IO ExprRef
lit = add . Literal

bin : ExprPool => BinOp -> IO ExprRef -> IO ExprRef -> IO ExprRef
bin op l r = add (Binary op !l !r)

main : IO ()
main = do
  a <- newIORef []
  b <- newIORef []
  let [poolA] ExprPool where exprs = a
      [poolB] ExprPool where exprs = b
  e <- bin @{poolA} Div (bin @{poolA} Mul (bin @{poolA} Sub (lit @{poolA} 7) (lit @{poolA} 10)) (lit @{poolA} 7))
                        (lit @{poolA} 2)
  printLn !(interp @{poolA} e)
  printLn !(interp @{poolB} !(bin @{poolB} Div (bin @{poolB} Add (lit @{poolB} 4) (lit @{poolB} 4))
                                                (bin @{poolB} Sub (lit @{poolB} 4) (lit @{poolB} 4))))
  printLn !(interp @{poolA} e)
