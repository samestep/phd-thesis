(* An ML functor: the pool is a module argument, applied once per pool. *)
type node = Lit of int | Add of int * int | Mul of int * int

module Expr (P : sig val pool : node Dynarray.t end) = struct
  let node n = Dynarray.add_last P.pool n; Dynarray.length P.pool - 1
  let lit n = node (Lit n)
  let add l r = node (Add (l, r))
  let mul l r = node (Mul (l, r))

  let rec eval e =
    match Dynarray.get P.pool e with
    | Lit n -> n
    | Add (l, r) -> eval l + eval r
    | Mul (l, r) -> eval l * eval r
end

let () =
  let open Expr (struct let pool = Dynarray.create () end) in
  let e = mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)) in
  Printf.printf "%d\n" (eval e);
  (let open Expr (struct let pool = Dynarray.create () end) in
   Printf.printf "%d\n" (eval (add (lit 4) (lit 4))));
  Printf.printf "%d\n" (eval e)
