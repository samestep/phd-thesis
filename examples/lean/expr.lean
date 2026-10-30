-- A reader monad: the pool is the environment, replaced with `withReader`.
inductive BinOp where
  | add | sub | mul | div

structure ExprRef where
  index : Nat
  deriving Inhabited

inductive Expr where
  | binary (op : BinOp) (lhs rhs : ExprRef)
  | literal (num : Int)
  deriving Inhabited

abbrev ExprPool := IO.Ref (Array Expr)

abbrev M := ReaderT ExprPool IO

def ExprPool.add (expr : Expr) : M ExprRef := do
  let pool ← read
  pool.modify (·.push expr)
  return ⟨(← ST.Ref.get pool).size - 1⟩

def ExprPool.get (expr : ExprRef) : M Expr := do
  return (← ST.Ref.get (← read))[expr.index]!

partial def interp (expr : ExprRef) : M Int := do
  match ← ExprPool.get expr with
  | .binary op lhs rhs =>
    let l ← interp lhs
    let r ← interp rhs
    return match op with
      | .add => l + r
      | .sub => l - r
      | .mul => l * r
      | .div => if r == 0 then 0 else l.tdiv r
  | .literal num => return num

def lit (n : Int) : M ExprRef := ExprPool.add (.literal n)
def bin (op : BinOp) (l r : M ExprRef) : M ExprRef := do ExprPool.add (.binary op (← l) (← r))

def main : IO Unit := do
  let a ← IO.mkRef #[]
  let b ← IO.mkRef #[]
  ReaderT.run (r := a) do
    let e ← bin .div (bin .mul (bin .sub (lit 7) (lit 10)) (lit 7)) (lit 2)
    IO.println (← interp e)
    withReader (fun _ => b) do
      IO.println (← interp (← bin .div (bin .add (lit 4) (lit 4)) (bin .sub (lit 4) (lit 4))))
    IO.println (← interp e)
