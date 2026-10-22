-- A reader monad: the pool is the environment, replaced with `withReader`.
inductive Node where
  | lit (n : Nat)
  | add (l r : Nat)
  | mul (l r : Nat)
  deriving Inhabited

abbrev M := ReaderT (IO.Ref (Array Node)) IO

def node (n : Node) : M Nat := do
  let pool ← read
  pool.modify (·.push n)
  return (← pool.get).size - 1

def lit (n : Nat) : M Nat := node (.lit n)
def add (l r : M Nat) : M Nat := do node (.add (← l) (← r))
def mul (l r : M Nat) : M Nat := do node (.mul (← l) (← r))

partial def eval (e : Nat) : M Nat := do
  match (← (← read).get)[e]! with
  | .lit n => return n
  | .add l r => return (← eval l) + (← eval r)
  | .mul l r => return (← eval l) * (← eval r)

def main : IO Unit := do
  let a ← IO.mkRef #[]
  let b ← IO.mkRef #[]
  ReaderT.run (r := a) do
    let e ← mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4))
    IO.println (← eval e)
    withReader (fun _ => b) do
      IO.println (← eval (← add (lit 4) (lit 4)))
    IO.println (← eval e)
