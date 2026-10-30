(* OCaml 5 effect handlers: `Pool` is performed, and the nearest handler answers. *)
open Effect
open Effect.Deep

type binop = Add | Sub | Mul | Div
type expr_ref = ExprRef of int
type expr = Binary of binop * expr_ref * expr_ref | Literal of int
type _ Effect.t += Pool : expr Dynarray.t Effect.t

let add expr = let p = perform Pool in Dynarray.add_last p expr; ExprRef (Dynarray.length p - 1)
let get (ExprRef i) = Dynarray.get (perform Pool) i

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

let with_pool f =
  let p = Dynarray.create () in
  try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Pool -> Some (fun (k : (a, _) continuation) -> continue k p)
        | _ -> None }

let () =
  with_pool (fun () ->
      let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
      Printf.printf "%d\n" (interp e);
      with_pool (fun () ->
          Printf.printf "%d\n" (interp (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)))));
      Printf.printf "%d\n" (interp e))
