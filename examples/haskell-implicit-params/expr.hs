{-# LANGUAGE ImplicitParams #-}
-- Implicit parameters (Lewis et al., POPL 2000): the pool is `?pool`.
import Data.IORef
import qualified Data.Sequence as S

data Node = Lit Int | Add Int Int | Mul Int Int

type Pool = IORef (S.Seq Node)

node :: (?pool :: Pool) => Node -> IO Int
node n = do
  modifyIORef ?pool (S.|> n)
  subtract 1 . S.length <$> readIORef ?pool

lit :: (?pool :: Pool) => Int -> IO Int
lit = node . Lit

add, mul :: (?pool :: Pool) => IO Int -> IO Int -> IO Int
add l r = do x <- l; y <- r; node (Add x y)
mul l r = do x <- l; y <- r; node (Mul x y)

eval :: (?pool :: Pool) => Int -> IO Int
eval e = do
  nodes <- readIORef ?pool
  case S.index nodes e of
    Lit n -> pure n
    Add l r -> (+) <$> eval l <*> eval r
    Mul l r -> (*) <$> eval l <*> eval r

main :: IO ()
main = do
  a <- newIORef S.empty
  let ?pool = a
  e <- mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4))
  print =<< eval e
  b <- newIORef S.empty
  do
    let ?pool = b
    f <- add (lit 4) (lit 4)
    print =<< eval f
  print =<< eval e
