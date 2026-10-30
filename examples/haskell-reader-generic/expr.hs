{-# LANGUAGE TypeFamilies #-}
-- A type class with an associated type: the environment is the pool, `Ref p` is its index type,
-- and every signature mentions `p`. A pool of another type can't be swapped in with `local`.
import Control.Monad.Reader
import Data.IORef
import qualified Data.Sequence as S

data BinOp = Add | Sub | Mul | Div deriving (Enum)

data Expr r = Binary BinOp r r | Literal Int

class Ast p where
  type Ref p
  add :: Expr (Ref p) -> M p (Ref p)
  get :: Ref p -> M p (Expr (Ref p))

type M p = ReaderT p IO

interp :: Ast p => Ref p -> M p Int
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

lit :: Ast p => Int -> M p (Ref p)
lit = add . Literal

bin :: Ast p => BinOp -> M p (Ref p) -> M p (Ref p) -> M p (Ref p)
bin op l r = do x <- l; y <- r; add (Binary op x y)

code :: BinOp -> Int
code = succ . fromEnum

opOf :: Int -> BinOp
opOf = toEnum . pred

-- Representation 1: a node is an index into parallel lists.
newtype Idx = Idx Int

data Columns = Columns {ops, lhs, rhs :: IORef (S.Seq Int)}

newColumns :: IO Columns
newColumns = Columns <$> newIORef S.empty <*> newIORef S.empty <*> newIORef S.empty

instance Ast Columns where
  type Ref Columns = Idx
  add expr = do
    c <- ask
    let (op, l, r) = case expr of
          Binary o (Idx x) (Idx y) -> (code o, x, y)
          Literal num -> (0, num, 0)
    liftIO $ do
      modifyIORef (ops c) (S.|> op)
      modifyIORef (lhs c) (S.|> l)
      modifyIORef (rhs c) (S.|> r)
      Idx . subtract 1 . S.length <$> readIORef (ops c)
  get (Idx i) = do
    c <- ask
    let at col = liftIO $ (`S.index` i) <$> readIORef (col c)
    op <- at ops
    if op == 0
      then Literal <$> at lhs
      else Binary (opOf op) <$> (Idx <$> at lhs) <*> (Idx <$> at rhs)

-- Representation 2: a node is an index into one list of triples.
newtype Slot = Slot Int

newtype Triples = Triples (IORef (S.Seq Int))

newTriples :: IO Triples
newTriples = Triples <$> newIORef S.empty

instance Ast Triples where
  type Ref Triples = Slot
  add expr = do
    Triples t <- ask
    liftIO $ do
      let row = case expr of
            Binary op (Slot l) (Slot r) -> [code op, l, r]
            Literal num -> [0, num, 0]
      modifyIORef t (<> S.fromList row)
      Slot . subtract 1 . (`div` 3) . S.length <$> readIORef t
  get (Slot i) = do
    Triples t <- ask
    s <- liftIO $ readIORef t
    let at k = S.index s (3 * i + k)
    pure $ if at 0 == 0 then Literal (at 1) else Binary (opOf (at 0)) (Slot (at 1)) (Slot (at 2))

main :: IO ()
main = do
  a <- newColumns
  b <- newTriples
  flip runReaderT a $ do
    e <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
    liftIO . print =<< interp e
    withReaderT (const b) $ do
      f <- bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))
      liftIO . print =<< interp f
    liftIO . print =<< interp e
