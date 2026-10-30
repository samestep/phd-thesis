{-# LANGUAGE ImplicitParams #-}
-- Implicit parameters (Lewis et al., POPL 2000): the pool is `?pool`.
import Data.IORef
import qualified Data.Sequence as S

data BinOp = Add | Sub | Mul | Div

data Expr = Binary BinOp ExprRef ExprRef | Literal Int

newtype ExprRef = ExprRef Int

type ExprPool = IORef (S.Seq Expr)

add :: (?pool :: ExprPool) => Expr -> IO ExprRef
add expr = do
  modifyIORef ?pool (S.|> expr)
  ExprRef . subtract 1 . S.length <$> readIORef ?pool

get :: (?pool :: ExprPool) => ExprRef -> IO Expr
get (ExprRef i) = (`S.index` i) <$> readIORef ?pool

interp :: (?pool :: ExprPool) => ExprRef -> IO Int
interp expr = do
  e <- get expr
  case e of
    Binary op lhs rhs -> do
      l <- interp lhs
      r <- interp rhs
      pure $ case op of
        Add -> l + r
        Sub -> l - r
        Mul -> l * r
        Div -> if r == 0 then 0 else l `quot` r
    Literal num -> pure num

lit :: (?pool :: ExprPool) => Int -> IO ExprRef
lit = add . Literal

bin :: (?pool :: ExprPool) => BinOp -> IO ExprRef -> IO ExprRef -> IO ExprRef
bin op l r = do x <- l; y <- r; add (Binary op x y)

main :: IO ()
main = do
  a <- newIORef S.empty
  let ?pool = a
  e <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  print =<< interp e
  b <- newIORef S.empty
  do
    let ?pool = b
    f <- bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))
    print =<< interp f
  print =<< interp e
