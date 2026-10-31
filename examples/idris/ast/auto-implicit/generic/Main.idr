-- Auto-implicit arguments over a record of closures: `{auto ast : Ast ref}` is filled from the
-- local context, picked by its index type `ref`. Search won't guess `ref`, so each built tree's
-- type is written out. (Two pools with the same index type would still be ambiguous.)
import Data.IORef
import Data.List
import Data.Maybe

data BinOp = Add | Sub | Mul | Div

data Expr ref = Binary BinOp ref ref | Literal Integer

-- Idris's `div` rounds down; the post's division truncates toward zero.
quot : Integer -> Integer -> Integer
quot l r = let q = abs l `div` abs r in if (l < 0) /= (r < 0) then negate q else q

record Ast ref where
  constructor MkAst
  add : Expr ref -> IO ref
  get : ref -> IO (Expr ref)

interp : {auto ast : Ast ref} -> ref -> IO Integer
interp expr = case !(ast.get expr) of
  Binary op lhs rhs => do
    l <- interp lhs
    r <- interp rhs
    pure $ case op of
      Add => l + r
      Sub => l - r
      Mul => l * r
      Div => if r == 0 then 0 else quot l r
  Literal num => pure num

lit : {auto ast : Ast ref} -> Integer -> IO ref
lit = ast.add . Literal

bin : {auto ast : Ast ref} -> BinOp -> IO ref -> IO ref -> IO ref
bin op l r = ast.add (Binary op !l !r)

code : BinOp -> Integer
code Add = 1
code Sub = 2
code Mul = 3
code Div = 4

opOf : Integer -> BinOp
opOf 1 = Add
opOf 2 = Sub
opOf 3 = Mul
opOf _ = Div

at : List Integer -> Nat -> Integer
at xs i = fromMaybe 0 (getAt i xs)

-- Representation 1: a node is an index into parallel lists.
record Idx where
  constructor MkIdx
  index : Nat

columns : IO (Ast Idx)
columns = do
  ops <- newIORef []
  lhs <- newIORef []
  rhs <- newIORef []
  pure $ MkAst
    (\expr => do
      let (op, l, r) = the (Integer, Integer, Integer) $ case expr of
            Binary op (MkIdx l) (MkIdx r) => (code op, cast l, cast r)
            Literal num => (0, num, 0)
      modifyIORef ops (++ [op])
      modifyIORef lhs (++ [l])
      modifyIORef rhs (++ [r])
      pure (MkIdx (length !(readIORef ops) `minus` 1)))
    (\(MkIdx i) => do
      let (op, l, r) = (at !(readIORef ops) i, at !(readIORef lhs) i, at !(readIORef rhs) i)
      pure $ if op == 0 then Literal l else Binary (opOf op) (MkIdx (cast l)) (MkIdx (cast r)))

-- Representation 2: a node is an index into one list of triples.
record Slot where
  constructor MkSlot
  index : Nat

triples : IO (Ast Slot)
triples = do
  triples <- newIORef []
  pure $ MkAst
    (\expr => do
      modifyIORef triples $ (++ case expr of
        Binary op (MkSlot l) (MkSlot r) => [code op, cast l, cast r]
        Literal num => [0, num, 0])
      pure (MkSlot (integerToNat (natToInteger (length !(readIORef triples)) `div` 3 - 1))))
    (\(MkSlot i) => do
      let t = !(readIORef triples)
      let (op, l, r) = (at t (3 * i), at t (3 * i + 1), at t (3 * i + 2))
      pure $ if op == 0 then Literal l else Binary (opOf op) (MkSlot (cast l)) (MkSlot (cast r)))

main : IO ()
main = do
  a <- columns
  e : Idx <- bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
  printLn !(interp e)
  b <- triples
  f : Slot <- bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4))
  printLn !(interp f)
  printLn !(interp e)
