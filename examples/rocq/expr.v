(* Type classes: `Context {P : Pool}` makes the pool an implicit argument. *)
Open Scope list_scope.
Inductive node := Lit (n : nat) | Add (l r : nat) | Mul (l r : nat).

Class Pool := { nodes : list node }.

Fixpoint nth (ns : list node) (i : nat) : node :=
  match ns, i with
  | nil, _ => Lit 0
  | n :: _, 0 => n
  | _ :: ns, S i => nth ns i
  end.

Section Eval.
  Context {P : Pool}.

  Fixpoint eval (fuel e : nat) : nat :=
    match fuel with
    | 0 => 0
    | S fuel =>
        match nth nodes e with
        | Lit n => n
        | Add l r => eval fuel l + eval fuel r
        | Mul l r => eval fuel l * eval fuel r
        end
    end.
End Eval.

(* Building threads the pool through; `eval` finds it by instance resolution. *)
Definition build := list node -> list node * nat.

Definition node' (n : node) : build := fun ns => (ns ++ n :: nil, length ns).
Definition lit n := node' (Lit n).
Definition add (l r : build) : build := fun ns =>
  let (ns1, x) := l ns in let (ns2, y) := r ns1 in node' (Add x y) ns2.
Definition mul (l r : build) : build := fun ns =>
  let (ns1, x) := l ns in let (ns2, y) := r ns1 in node' (Mul x y) ns2.

Definition a := mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)) nil.
Definition outer := let _ : Pool := {| nodes := fst a |} in eval 100 (snd a).
Definition b := add (lit 4) (lit 4) nil.
Definition inner := let _ : Pool := {| nodes := fst b |} in eval 100 (snd b).

Eval vm_compute in outer.
Eval vm_compute in inner.
Eval vm_compute in outer.
