-- The reader monad: the pool is the environment, replaced with `local`.
import Control.Monad.Reader
import Data.IORef
import qualified Data.Sequence as S

data Node = Lit Int | Add Int Int | Mul Int Int

type M = ReaderT (IORef (S.Seq Node)) IO

node :: Node -> M Int
node n = do
  pool <- ask
  liftIO $ modifyIORef pool (S.|> n)
  liftIO $ subtract 1 . S.length <$> readIORef pool

lit :: Int -> M Int
lit = node . Lit

add, mul :: M Int -> M Int -> M Int
add l r = do x <- l; y <- r; node (Add x y)
mul l r = do x <- l; y <- r; node (Mul x y)

eval :: Int -> M Int
eval e = do
  nodes <- liftIO . readIORef =<< ask
  case S.index nodes e of
    Lit n -> pure n
    Add l r -> (+) <$> eval l <*> eval r
    Mul l r -> (*) <$> eval l <*> eval r

main :: IO ()
main = do
  a <- newIORef S.empty
  b <- newIORef S.empty
  flip runReaderT a $ do
    e <- mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4))
    liftIO . print =<< eval e
    local (const b) $ do
      f <- add (lit 4) (lit 4)
      liftIO . print =<< eval f
    liftIO . print =<< eval e
