(* Modular implicits: the pool is an implicit module argument, resolved by type. *)
type node = Lit of int | Add of int * int | Mul of int * int

module type POOL = sig val nodes : node list ref end

let node {P : POOL} n = P.nodes := !P.nodes @ [n]; List.length !P.nodes - 1
let lit {P : POOL} n = node (Lit n)
let add {P : POOL} l r = node (Add (l, r))
let mul {P : POOL} l r = node (Mul (l, r))

let rec eval : {P : POOL} -> int -> int = fun {P : POOL} e ->
  match List.nth !P.nodes e with
  | Lit n -> n
  | Add (l, r) -> eval l + eval r
  | Mul (l, r) -> eval l * eval r

implicit module A = struct let nodes : node list ref = ref [] end

let () =
  let e = mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)) in
  Printf.printf "%d\n" (eval e);
  (* A local implicit module does not shadow `A`: both match, so resolution is
     ambiguous, and the inner pool has to be applied explicitly. *)
  (let implicit module B = struct let nodes : node list ref = ref [] end in
   Printf.printf "%d\n" (eval {B} (add {B} (lit {B} 4) (lit {B} 4))));
  Printf.printf "%d\n" (eval e)
