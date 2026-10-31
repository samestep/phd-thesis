-- The reader monad: the pool is the environment, replaced with `local`.
import Control.Monad.Reader
import Data.IORef
import qualified Data.Sequence as S

data BinOp = Add | Sub | Mul | Div

data Expr = Binary BinOp ExprRef ExprRef | Literal Int

newtype ExprRef = ExprRef Int

type ExprPool = IORef (S.Seq Expr)

type M = ReaderT ExprPool IO

add :: Expr -> M ExprRef
add expr = do
  pool <- ask
  liftIO $ modifyIORef pool (S.|> expr)
  liftIO $ ExprRef . subtract 1 . S.length <$> readIORef pool

get :: ExprRef -> M Expr
get (ExprRef i) = do
  pool <- ask
  liftIO $ (`S.index` i) <$> readIORef pool

interp :: ExprRef -> M Int
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

lit :: Int -> M ExprRef
lit = add . Literal

bin :: BinOp -> M ExprRef -> M ExprRef -> M ExprRef
bin op l r = do x <- l; y <- r; add (Binary op x y)

main :: IO ()
main = do
  a <- newIORef S.empty
  b <- newIORef S.empty
  flip runReaderT a $ do
    e <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
    liftIO . print =<< interp e
    local (const b) $ do
      f <- bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))
      liftIO . print =<< interp f
    liftIO . print =<< interp e
