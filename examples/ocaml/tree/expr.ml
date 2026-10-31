(* The tree Sampson starts from: each node holds its children directly, and
   the garbage collector frees them, so nothing needs a pool. *)
type binop = Add | Sub | Mul | Div
type expr = Binary of binop * expr * expr | Literal of int

let rec interp expr =
  match expr with
  | Binary (op, lhs, rhs) ->
      let l = interp lhs and r = interp rhs in
      (match op with
       | Add -> l + r
       | Sub -> l - r
       | Mul -> l * r
       | Div -> if r = 0 then 0 else l / r)
  | Literal num -> num

let lit n = Literal n
let bin op l r = Binary (op, l, r)

let () =
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
  Printf.printf "%d\n" (interp e);
  (let f = bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) in
   Printf.printf "%d\n" (interp f));
  Printf.printf "%d\n" (interp e)
