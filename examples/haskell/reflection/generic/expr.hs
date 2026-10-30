{-# LANGUAGE RankNTypes, ScopedTypeVariables, FlexibleContexts, KindSignatures, TypeFamilies #-}
-- Implicit configurations over a type class with an associated type: `s` reflects a pool of some
-- type `p`, so every signature carries `Reifies s p, Ast p` and spells the index type as `Ref p`.
import Data.IORef
import Data.Kind (Type)
import Data.Proxy
import Data.Reflection
import qualified Data.Sequence as S

data BinOp = Add | Sub | Mul | Div deriving (Enum)

data Expr r = Binary BinOp r r | Literal Int

class Ast p where
  type Ref p
  add :: p -> Expr (Ref p) -> IO (Ref p)
  get :: p -> Ref p -> IO (Expr (Ref p))

newtype M (s :: Type) a = M { runM :: IO a }

instance Functor (M s) where fmap f (M m) = M (fmap f m)
instance Applicative (M s) where pure = M . pure; M f <*> M x = M (f <*> x)
instance Monad (M s) where M m >>= k = M (m >>= runM . k)

pool :: forall s p. Reifies s p => M s p
pool = pure (reflect (Proxy :: Proxy s))

interp :: (Reifies s p, Ast p) => Ref p -> M s Int
interp expr = do
  p <- pool
  e <- M (get p expr)
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

lit :: (Reifies s p, Ast p) => Int -> M s (Ref p)
lit n = do p <- pool; M (add p (Literal n))

bin :: (Reifies s p, Ast p) => BinOp -> M s (Ref p) -> M s (Ref p) -> M s (Ref p)
bin op l r = do x <- l; y <- r; p <- pool; M (add p (Binary op x y))

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
  add c expr = do
    let (op, l, r) = case expr of
          Binary o (Idx x) (Idx y) -> (code o, x, y)
          Literal num -> (0, num, 0)
    modifyIORef (ops c) (S.|> op)
    modifyIORef (lhs c) (S.|> l)
    modifyIORef (rhs c) (S.|> r)
    Idx . subtract 1 . S.length <$> readIORef (ops c)
  get c (Idx i) = do
    let at col = (`S.index` i) <$> readIORef (col c)
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
  add (Triples t) expr = do
    let row = case expr of
          Binary op (Slot l) (Slot r) -> [code op, l, r]
          Literal num -> [0, num, 0]
    modifyIORef t (<> S.fromList row)
    Slot . subtract 1 . (`div` 3) . S.length <$> readIORef t
  get (Triples t) (Slot i) = do
    s <- readIORef t
    let at k = S.index s (3 * i + k)
    pure $ if at 0 == 0 then Literal (at 1) else Binary (opOf (at 0)) (Slot (at 1)) (Slot (at 2))

withPool :: forall p a. IO p -> (forall s. Reifies s p => M s a) -> IO a
withPool new m = do p <- new; reify p (\(_ :: Proxy s) -> runM (m :: M s a))

main :: IO ()
main = withPool newColumns $ do
  e <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  M . print =<< interp e
  M (withPool newTriples (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) >>= interp))
    >>= M . print
  M . print =<< interp e
