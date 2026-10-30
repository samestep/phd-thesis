-- A reader monad over a structure of closures: the index type is a parameter of the
-- environment, so a pool with another index type needs another monad, not `withReader`.
inductive BinOp where
  | add | sub | mul | div

inductive Expr (Ref : Type) where
  | binary (op : BinOp) (lhs rhs : Ref)
  | literal (num : Int)

structure Ast (Ref : Type) where
  add : Expr Ref → IO Ref
  get : Ref → IO (Expr Ref)

abbrev M (Ref : Type) := ReaderT (Ast Ref) IO

partial def interp {Ref : Type} (expr : Ref) : M Ref Int := do
  match ← (← read).get expr with
  | .binary op lhs rhs =>
    let l ← interp lhs
    let r ← interp rhs
    return match op with
      | .add => l + r
      | .sub => l - r
      | .mul => l * r
      | .div => if r == 0 then 0 else l.tdiv r
  | .literal num => return num

def lit {Ref : Type} (n : Int) : M Ref Ref := do (← read).add (.literal n)
def bin {Ref : Type} (op : BinOp) (l r : M Ref Ref) : M Ref Ref := do
  (← read).add (.binary op (← l) (← r))

def BinOp.code : BinOp → Int
  | .add => 1 | .sub => 2 | .mul => 3 | .div => 4

def BinOp.ofCode : Int → BinOp
  | 1 => .add | 2 => .sub | 3 => .mul | _ => .div

-- Representation 1: a node is an index into parallel lists.
structure Idx where
  index : Nat

def columns : IO (Ast Idx) := do
  let ops ← IO.mkRef (#[] : Array Int)
  let lhs ← IO.mkRef (#[] : Array Int)
  let rhs ← IO.mkRef (#[] : Array Int)
  return {
    add := fun expr => do
      let (op, l, r) := match expr with
        | .binary op ⟨l⟩ ⟨r⟩ => (op.code, (l : Int), (r : Int))
        | .literal num => (0, num, 0)
      ops.modify (·.push op); lhs.modify (·.push l); rhs.modify (·.push r)
      return ⟨(← ops.get).size - 1⟩
    get := fun ⟨i⟩ => do
      let (op, l, r) := ((← ops.get)[i]!, (← lhs.get)[i]!, (← rhs.get)[i]!)
      return if op == 0 then .literal l else .binary (.ofCode op) ⟨l.toNat⟩ ⟨r.toNat⟩
  }

-- Representation 2: a node is an index into one list of triples.
structure Slot where
  index : Nat

def triples : IO (Ast Slot) := do
  let triples ← IO.mkRef (#[] : Array Int)
  return {
    add := fun expr => do
      match expr with
      | .binary op ⟨l⟩ ⟨r⟩ => triples.modify (· ++ #[op.code, l, r])
      | .literal num => triples.modify (· ++ #[0, num, 0])
      return ⟨(← triples.get).size / 3 - 1⟩
    get := fun ⟨i⟩ => do
      let t ← triples.get
      return match t[3 * i]! with
        | 0 => .literal t[3 * i + 1]!
        | op => .binary (.ofCode op) ⟨t[3 * i + 1]!.toNat⟩ ⟨t[3 * i + 2]!.toNat⟩
  }

def main : IO Unit := do
  let a ← columns
  let b ← triples
  ReaderT.run (r := a) do
    let e ← bin .div (bin .mul (bin .sub (lit 7) (lit 10)) (lit 7)) (lit 2)
    IO.println (← interp e)
    ReaderT.run (m := IO) (r := b) do
      IO.println (← interp (← bin .div (bin .add (lit 4) (lit 4)) (bin .sub (lit 4) (lit 4))))
    IO.println (← interp e)
