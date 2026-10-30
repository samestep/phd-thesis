(* Type classes: `Ast pool ref` is a representation, picked by its pool and index types, and
   `Pool pool` is the built pool; `Context` makes both, and both types, implicit arguments. *)
From Stdlib Require Import ZArith List.
Import ListNotations.
Open Scope Z_scope.

Inductive binop := Add | Sub | Mul | Div.
Inductive expr (ref : Type) := Binary (op : binop) (lhs rhs : ref) | Literal (num : Z).
Arguments Binary {ref}. Arguments Literal {ref}.

Class Ast (pool ref : Type) := {
  add : expr ref -> pool -> pool * ref;
  get : pool -> ref -> expr ref }.

Class Pool (pool : Type) := the_pool : pool.

Section Interp.
  Context {pool ref : Type} `{Ast pool ref} `{Pool pool}.

  Fixpoint interp (fuel : nat) (e : ref) : Z :=
    match fuel with
    | O => 0
    | S fuel =>
        match get the_pool e with
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
Definition build pool ref := pool -> pool * ref.
Generalizable Variables pool ref.

Definition lit `{Ast pool ref} n : build pool ref := add (Literal n).
Definition bin `{Ast pool ref} op (l r : build pool ref) : build pool ref := fun p =>
  let (p1, x) := l p in let (p2, y) := r p1 in add (Binary op x y) p2.

Definition code op : Z := match op with Add => 1 | Sub => 2 | Mul => 3 | Div => 4 end.
Definition op_of (c : Z) := match c with 1 => Add | 2 => Sub | 3 => Mul | _ => Div end.

(* Representation 1: a node is an index into parallel lists. *)
Inductive idx := Idx (i : nat).
Record columns := Columns { ops : list Z; lhss : list Z; rhss : list Z }.

#[export] Instance columns_ast : Ast columns idx := {
  add e '(Columns os ls rs) :=
    let '(op, l, r) := match e with
                       | Binary op (Idx l) (Idx r) => (code op, Z.of_nat l, Z.of_nat r)
                       | Literal num => (0, num, 0)
                       end in
    (Columns (os ++ [op]) (ls ++ [l]) (rs ++ [r]), Idx (length os));
  get '(Columns os ls rs) '(Idx i) :=
    let l := nth i ls 0 in
    match nth i os 0 with
    | 0 => Literal l
    | op => Binary (op_of op) (Idx (Z.to_nat l)) (Idx (Z.to_nat (nth i rs 0)))
    end }.

(* Representation 2: a node is an index into one list of triples. *)
Inductive slot := Slot (i : nat).
Inductive triples := Triples (t : list Z).

#[export] Instance triples_ast : Ast triples slot := {
  add e '(Triples t) :=
    let row := match e with
               | Binary op (Slot l) (Slot r) => [code op; Z.of_nat l; Z.of_nat r]
               | Literal num => [0; num; 0]
               end in
    (Triples (t ++ row), Slot (Nat.div (length t) 3));
  get '(Triples t) '(Slot i) :=
    let cell k := nth (3 * i + k)%nat t 0 in
    match cell 0%nat with
    | 0 => Literal (cell 1%nat)
    | op => Binary (op_of op) (Slot (Z.to_nat (cell 1%nat))) (Slot (Z.to_nat (cell 2%nat)))
    end }.

Definition a := bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) (Columns [] [] []).
Definition outer := let _ : Pool columns := fst a in interp 100 (snd a).
Definition b := bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) (Triples []).
Definition inner := let _ : Pool triples := fst b in interp 100 (snd b).

Eval vm_compute in outer.
Eval vm_compute in inner.
Eval vm_compute in outer.
