-- Auto-implicit arguments: `{auto pool : Pool}` is filled from the local context.
-- (Two pools in scope are ambiguous rather than shadowed, so the inner one gets its own function.)
import Data.IORef
import Data.List

data Node = Lit Integer | Add Nat Nat | Mul Nat Nat

record Pool where
  constructor MkPool
  nodes : IORef (List Node)

node : {auto pool : Pool} -> Node -> IO Nat
node n = do
  modifyIORef pool.nodes (++ [n])
  pure (length !(readIORef pool.nodes) `minus` 1)

lit : {auto pool : Pool} -> Integer -> IO Nat
lit = node . Lit

add, mul : {auto pool : Pool} -> IO Nat -> IO Nat -> IO Nat
add l r = node (Add !l !r)
mul l r = node (Mul !l !r)

eval : {auto pool : Pool} -> Nat -> IO Integer
eval e = case getAt e !(readIORef pool.nodes) of
  Just (Lit n) => pure n
  Just (Add l r) => pure (!(eval l) + !(eval r))
  Just (Mul l r) => pure (!(eval l) * !(eval r))
  Nothing => pure 0

elsewhere : IO ()
elsewhere = do
  b <- MkPool <$> newIORef []
  printLn !(eval !(add (lit 4) (lit 4)))

main : IO ()
main = do
  a <- MkPool <$> newIORef []
  e <- mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4))
  printLn !(eval e)
  elsewhere
  printLn !(eval e)
