-- Auto-implicit arguments: `{auto pool : ExprPool}` is filled from the local context.
-- (Two pools in scope are ambiguous rather than shadowed, so the inner one gets its own function.)
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

record ExprPool where
  constructor MkExprPool
  exprs : IORef (List Expr)

add : {auto pool : ExprPool} -> Expr -> IO ExprRef
add expr = do
  modifyIORef pool.exprs (++ [expr])
  pure (MkExprRef (length !(readIORef pool.exprs) `minus` 1))

get : {auto pool : ExprPool} -> ExprRef -> IO Expr
get expr = pure (fromMaybe (Literal 0) (getAt expr.index !(readIORef pool.exprs)))

interp : {auto pool : ExprPool} -> ExprRef -> IO Integer
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

lit : {auto pool : ExprPool} -> Integer -> IO ExprRef
lit = add . Literal

bin : {auto pool : ExprPool} -> BinOp -> IO ExprRef -> IO ExprRef -> IO ExprRef
bin op l r = add (Binary op !l !r)

elsewhere : IO ()
elsewhere = do
  b <- MkExprPool <$> newIORef []
  printLn !(interp !(bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))))

main : IO ()
main = do
  a <- MkExprPool <$> newIORef []
  e <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  printLn !(interp e)
  elsewhere
  printLn !(interp e)
