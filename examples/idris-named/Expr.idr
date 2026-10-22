-- Named implementations: two `Pool` implementations, picked by name with `@{...}`.
import Data.IORef
import Data.List

data Node = Lit Integer | Add Nat Nat | Mul Nat Nat

interface Pool where
  nodes : IORef (List Node)

node : Pool => Node -> IO Nat
node n = do
  modifyIORef nodes (++ [n])
  pure (length !(readIORef nodes) `minus` 1)

lit : Pool => Integer -> IO Nat
lit = node . Lit

add, mul : Pool => IO Nat -> IO Nat -> IO Nat
add l r = node (Add !l !r)
mul l r = node (Mul !l !r)

eval : Pool => Nat -> IO Integer
eval e = case getAt e !(readIORef nodes) of
  Just (Lit n) => pure n
  Just (Add l r) => pure (!(eval l) + !(eval r))
  Just (Mul l r) => pure (!(eval l) * !(eval r))
  Nothing => pure 0

main : IO ()
main = do
  a <- newIORef []
  b <- newIORef []
  let [poolA] Pool where nodes = a
      [poolB] Pool where nodes = b
  e <- mul @{poolA} (add @{poolA} (lit @{poolA} 1) (lit @{poolA} 2))
                    (add @{poolA} (lit @{poolA} 3) (lit @{poolA} 4))
  printLn !(eval @{poolA} e)
  printLn !(eval @{poolB} !(add @{poolB} (lit @{poolB} 4) (lit @{poolB} 4)))
  printLn !(eval @{poolA} e)
