(* For now the OCaml functor version, unchanged, compiled with OxCaml: a
   first check that the toolchain builds and runs everywhere. *)
(* An ML functor: the pool is a module argument, applied once per pool. *)
type binop = Add | Sub | Mul | Div
type expr_ref = ExprRef of int
type expr = Binary of binop * expr_ref * expr_ref | Literal of int

module Interp (P : sig val pool : expr Dynarray.t end) = struct
  let add expr = Dynarray.add_last P.pool expr; ExprRef (Dynarray.length P.pool - 1)
  let get (ExprRef i) = Dynarray.get P.pool i

  let rec interp expr =
    match get expr with
    | Binary (op, lhs, rhs) ->
        let l = interp lhs and r = interp rhs in
        (match op with
         | Add -> l + r
         | Sub -> l - r
         | Mul -> l * r
         | Div -> if r = 0 then 0 else l / r)
    | Literal num -> num

  let lit n = add (Literal n)
  let bin op l r = add (Binary (op, l, r))
end

let () =
  let open Interp (struct let pool = Dynarray.create () end) in
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
  Printf.printf "%d\n" (interp e);
  (let open Interp (struct let pool = Dynarray.create () end) in
   Printf.printf "%d\n" (interp (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)))));
  Printf.printf "%d\n" (interp e)
