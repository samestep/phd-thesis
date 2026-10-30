(* Modular implicits: the pool is an implicit module argument, resolved by type. *)
type binop = Add | Sub | Mul | Div
type expr_ref = ExprRef of int
type expr = Binary of binop * expr_ref * expr_ref | Literal of int

module type POOL = sig val exprs : expr list ref end

let add {P : POOL} expr = P.exprs := !P.exprs @ [expr]; ExprRef (List.length !P.exprs - 1)
let get {P : POOL} (ExprRef i) = List.nth !P.exprs i

let rec interp : {P : POOL} -> expr_ref -> int = fun {P : POOL} expr ->
  match get expr with
  | Binary (op, lhs, rhs) ->
      let l = interp lhs and r = interp rhs in
      (match op with
       | Add -> l + r
       | Sub -> l - r
       | Mul -> l * r
       | Div -> if r = 0 then 0 else l / r)
  | Literal num -> num

let lit {P : POOL} n = add (Literal n)
let bin {P : POOL} op l r = add (Binary (op, l, r))

implicit module A = struct let exprs : expr list ref = ref [] end

let () =
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
  Printf.printf "%d\n" (interp e);
  (* A local implicit module does not shadow `A`: both match, so resolution is
     ambiguous, and the inner pool has to be applied explicitly. *)
  (let implicit module B = struct let exprs : expr list ref = ref [] end in
   Printf.printf "%d\n"
     (interp {B} (bin {B} Div (bin {B} Add (lit {B} 4) (lit {B} 4)) (bin {B} Sub (lit {B} 4) (lit {B} 4)))));
  Printf.printf "%d\n" (interp e)
