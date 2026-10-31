-- Named implementations: an `Ast ref` interface over the index type `ref`, with one named
-- implementation per pool, picked with `@{...}`; the index type follows from the name.
import Data.IORef
import Data.List
import Data.Maybe

data BinOp = Add | Sub | Mul | Div

data Expr ref = Binary BinOp ref ref | Literal Integer

-- Idris's `div` rounds down; the post's division truncates toward zero.
quot : Integer -> Integer -> Integer
quot l r = let q = abs l `div` abs r in if (l < 0) /= (r < 0) then negate q else q

interface Ast ref where
  add : Expr ref -> IO ref
  get : ref -> IO (Expr ref)

interp : Ast ref => ref -> IO Integer
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

lit : Ast ref => Integer -> IO ref
lit = add . Literal

bin : Ast ref => BinOp -> IO ref -> IO ref -> IO ref
bin op l r = add (Binary op !l !r)

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

record Columns where
  constructor MkColumns
  ops, lhs, rhs : IORef (List Integer)

columnsAdd : Columns -> Expr Idx -> IO Idx
columnsAdd c expr = do
  let (op, l, r) = the (Integer, Integer, Integer) $ case expr of
        Binary op (MkIdx l) (MkIdx r) => (code op, cast l, cast r)
        Literal num => (0, num, 0)
  modifyIORef c.ops (++ [op])
  modifyIORef c.lhs (++ [l])
  modifyIORef c.rhs (++ [r])
  pure (MkIdx (length !(readIORef c.ops) `minus` 1))

columnsGet : Columns -> Idx -> IO (Expr Idx)
columnsGet c (MkIdx i) = do
  let (op, l, r) = (at !(readIORef c.ops) i, at !(readIORef c.lhs) i, at !(readIORef c.rhs) i)
  pure $ if op == 0 then Literal l else Binary (opOf op) (MkIdx (cast l)) (MkIdx (cast r))

-- Representation 2: a node is an index into one list of triples.
record Slot where
  constructor MkSlot
  index : Nat

triplesAdd : IORef (List Integer) -> Expr Slot -> IO Slot
triplesAdd triples expr = do
  modifyIORef triples $ (++ case expr of
    Binary op (MkSlot l) (MkSlot r) => [code op, cast l, cast r]
    Literal num => [0, num, 0])
  pure (MkSlot (integerToNat (natToInteger (length !(readIORef triples)) `div` 3 - 1)))

triplesGet : IORef (List Integer) -> Slot -> IO (Expr Slot)
triplesGet triples (MkSlot i) = do
  let t = !(readIORef triples)
  let (op, l, r) = (at t (3 * i), at t (3 * i + 1), at t (3 * i + 2))
  pure $ if op == 0 then Literal l else Binary (opOf op) (MkSlot (cast l)) (MkSlot (cast r))

main : IO ()
main = do
  a <- [| MkColumns (newIORef []) (newIORef []) (newIORef []) |]
  b <- newIORef []
  let [poolA] Ast Idx where
        add = columnsAdd a
        get = columnsGet a
      [poolB] Ast Slot where
        add = triplesAdd b
        get = triplesGet b
  e <- bin @{poolA} Div (bin @{poolA} Mul (bin @{poolA} Sub (lit @{poolA} 7) (lit @{poolA} 10)) (lit @{poolA} 7))
                        (lit @{poolA} 2)
  printLn !(interp @{poolA} e)
  printLn !(interp @{poolB} !(bin @{poolB} Div (bin @{poolB} Add (lit @{poolB} 4) (lit @{poolB} 4))
                                                (bin @{poolB} Sub (lit @{poolB} 4) (lit @{poolB} 4))))
  printLn !(interp @{poolA} e)
