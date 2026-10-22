{-# LANGUAGE RankNTypes, ScopedTypeVariables, FlexibleContexts, KindSignatures #-}
-- Implicit configurations (Kiselyov & Shan, 2004): `reify` a pool as a type `s`, `reflect` it back.
import Data.IORef
import Data.Kind (Type)
import Data.Proxy
import Data.Reflection
import qualified Data.Sequence as S

data Node = Lit Int | Add Int Int | Mul Int Int

type Pool = IORef (S.Seq Node)

newtype M (s :: Type) a = M { runM :: IO a }

instance Functor (M s) where fmap f (M m) = M (fmap f m)
instance Applicative (M s) where pure = M . pure; M f <*> M x = M (f <*> x)
instance Monad (M s) where M m >>= k = M (m >>= runM . k)

pool :: forall s. Reifies s Pool => M s Pool
pool = pure (reflect (Proxy :: Proxy s))

node :: Reifies s Pool => Node -> M s Int
node n = do
  p <- pool
  M (modifyIORef p (S.|> n) >> subtract 1 . S.length <$> readIORef p)

lit :: Reifies s Pool => Int -> M s Int
lit = node . Lit

add, mul :: Reifies s Pool => M s Int -> M s Int -> M s Int
add l r = do x <- l; y <- r; node (Add x y)
mul l r = do x <- l; y <- r; node (Mul x y)

eval :: Reifies s Pool => Int -> M s Int
eval e = do
  nodes <- pool >>= M . readIORef
  case S.index nodes e of
    Lit n -> pure n
    Add l r -> (+) <$> eval l <*> eval r
    Mul l r -> (*) <$> eval l <*> eval r

withPool :: forall a. (forall s. Reifies s Pool => M s a) -> IO a
withPool m = do p <- newIORef S.empty; reify p (\(_ :: Proxy s) -> runM (m :: M s a))

main :: IO ()
main = withPool $ do
  e <- mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4))
  M . print =<< eval e
  M (withPool (add (lit 4) (lit 4) >>= eval)) >>= M . print
  M . print =<< eval e
