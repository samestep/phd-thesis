(* The tree Sampson starts from: each node holds its children as nested terms
   of an inductive type, so nothing needs a pool and `interp` needs no fuel. *)
From Stdlib Require Import ZArith.
Open Scope Z_scope.

Inductive binop := Add | Sub | Mul | Div.
Inductive expr := Binary (op : binop) (lhs rhs : expr) | Literal (num : Z).

Fixpoint interp (e : expr) : Z :=
  match e with
  | Binary op lhs rhs =>
      let l := interp lhs in
      let r := interp rhs in
      match op with
      | Add => l + r
      | Sub => l - r
      | Mul => l * r
      | Div => if r =? 0 then 0 else Z.quot l r
      end
  | Literal num => num
  end.

Definition lit := Literal.
Definition bin := Binary.

Definition e := bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2).
Definition outer := interp e.
Definition inner := let f := bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) in interp f.

Eval vm_compute in outer.
Eval vm_compute in inner.
Eval vm_compute in outer.
