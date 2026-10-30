(* Type classes: `Context {P : ExprPool}` makes the pool an implicit argument. *)
From Stdlib Require Import ZArith List.
Import ListNotations.
Open Scope Z_scope.

Inductive binop := Add | Sub | Mul | Div.
Inductive expr_ref := ExprRef (i : nat).
Inductive expr := Binary (op : binop) (lhs rhs : expr_ref) | Literal (num : Z).

Class ExprPool := { exprs : list expr }.

Section Interp.
  Context {P : ExprPool}.

  Definition get '(ExprRef i) : expr := nth i exprs (Literal 0).

  Fixpoint interp (fuel : nat) (e : expr_ref) : Z :=
    match fuel with
    | O => 0
    | S fuel =>
        match get e with
        | Binary op lhs rhs =>
            let l := interp fuel lhs in
            let r := interp fuel rhs in
            match op with
            | Add => l + r
            | Sub => l - r
            | Mul => l * r
            | Div => if r =? 0 then 0 else Z.quot l r
            end
        | Literal num => num
        end
    end.
End Interp.

(* Building threads the pool through; `interp` finds it by instance resolution. *)
Definition build := list expr -> list expr * expr_ref.

Definition add (e : expr) : build := fun es => (es ++ [e], ExprRef (length es)).
Definition lit n := add (Literal n).
Definition bin op (l r : build) : build := fun es =>
  let (es1, x) := l es in let (es2, y) := r es1 in add (Binary op x y) es2.

Definition a := bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) [].
Definition outer := let _ : ExprPool := {| exprs := fst a |} in interp 100 (snd a).
Definition b := bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) [].
Definition inner := let _ : ExprPool := {| exprs := fst b |} in interp 100 (snd b).

Eval vm_compute in outer.
Eval vm_compute in inner.
Eval vm_compute in outer.
