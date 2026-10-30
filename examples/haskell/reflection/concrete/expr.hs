{-# LANGUAGE RankNTypes, ScopedTypeVariables, FlexibleContexts, KindSignatures #-}
-- Implicit configurations (Kiselyov & Shan, 2004): `reify` a pool as a type `s`, `reflect` it back.
import Data.IORef
import Data.Kind (Type)
import Data.Proxy
import Data.Reflection
import qualified Data.Sequence as S

data BinOp = Add | Sub | Mul | Div

data Expr = Binary BinOp ExprRef ExprRef | Literal Int

newtype ExprRef = ExprRef Int

type ExprPool = IORef (S.Seq Expr)

newtype M (s :: Type) a = M { runM :: IO a }

instance Functor (M s) where fmap f (M m) = M (fmap f m)
instance Applicative (M s) where pure = M . pure; M f <*> M x = M (f <*> x)
instance Monad (M s) where M m >>= k = M (m >>= runM . k)

pool :: forall s. Reifies s ExprPool => M s ExprPool
pool = pure (reflect (Proxy :: Proxy s))

add :: Reifies s ExprPool => Expr -> M s ExprRef
add expr = do
  p <- pool
  M (modifyIORef p (S.|> expr) >> ExprRef . subtract 1 . S.length <$> readIORef p)

get :: Reifies s ExprPool => ExprRef -> M s Expr
get (ExprRef i) = do
  p <- pool
  M ((`S.index` i) <$> readIORef p)

interp :: Reifies s ExprPool => ExprRef -> M s Int
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

lit :: Reifies s ExprPool => Int -> M s ExprRef
lit = add . Literal

bin :: Reifies s ExprPool => BinOp -> M s ExprRef -> M s ExprRef -> M s ExprRef
bin op l r = do x <- l; y <- r; add (Binary op x y)

withPool :: forall a. (forall s. Reifies s ExprPool => M s a) -> IO a
withPool m = do p <- newIORef S.empty; reify p (\(_ :: Proxy s) -> runM (m :: M s a))

main :: IO ()
main = withPool $ do
  e <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  M . print =<< interp e
  M (withPool (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) >>= interp)) >>= M . print
  M . print =<< interp e
