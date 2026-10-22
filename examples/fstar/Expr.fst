(* Type classes: `{| pool |}` is filled by instance resolution from the context. *)
module Expr
open FStar.Tactics.V2
open FStar.List.Tot

type node = | Lit : nat -> node | Add : nat -> nat -> node | Mul : nat -> nat -> node

class pool = { nodes : list node }

let rec nth (ns : list node) (i : nat) : node =
  match ns with
  | [] -> Lit 0
  | n :: ns -> if i = 0 then n else nth ns (i - 1)

let rec eval {| pool |} (fuel e : nat) : Tot nat (decreases fuel) =
  if fuel = 0 then 0 else
  match nth nodes e with
  | Lit n -> n
  | Add l r -> eval (fuel - 1) l + eval (fuel - 1) r
  | Mul l r -> eval (fuel - 1) l `op_Multiply` eval (fuel - 1) r

(* Building threads the pool through; `eval` finds it by instance resolution. *)
type build = list node -> list node & nat

let node' (n : node) : build = fun ns -> (ns @ [n], length ns)
let lit n = node' (Lit n)
let add (l r : build) : build = fun ns -> let (ns1, x) = l ns in let (ns2, y) = r ns1 in node' (Add x y) ns2
let mul (l r : build) : build = fun ns -> let (ns1, x) = l ns in let (ns2, y) = r ns1 in node' (Mul x y) ns2

let a = mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)) []
let outer : nat = let p : pool = { nodes = fst a } in eval 100 (snd a)
let b = add (lit 4) (lit 4) []
let inner : nat = let p : pool = { nodes = fst b } in eval 100 (snd b)

let show (t : term) : Tac unit = print (term_to_string (norm_term [delta; zeta; iota; primops] t))
let _ = assert True by (show (`outer); show (`inner); show (`outer); trivial ())
