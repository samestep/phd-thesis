(* Modular implicits: the pool is an implicit module argument, resolved by
   type. Its index type is now part of that type, so annotating one reference
   is enough to pick the inner pool, instead of passing it everywhere. *)
type binop = Add | Sub | Mul | Div
type 'r expr = Binary of binop * 'r * 'r | Literal of int

module type AST = sig
  type t
  val add : t expr -> t
  val get : t -> t expr
end

let rec interp : {A : AST} -> A.t -> int = fun {A : AST} expr ->
  match A.get expr with
  | Binary (op, lhs, rhs) ->
      let l = interp lhs and r = interp rhs in
      (match op with
       | Add -> l + r
       | Sub -> l - r
       | Mul -> l * r
       | Div -> if r = 0 then 0 else l / r)
  | Literal num -> num

let lit {A : AST} n = A.add (Literal n)
let bin {A : AST} op l r = A.add (Binary (op, l, r))

let code = function Add -> 1 | Sub -> 2 | Mul -> 3 | Div -> 4
let op_of = function 1 -> Add | 2 -> Sub | 3 -> Mul | _ -> Div

(* Representation 1: a node is an index into parallel lists. *)
module Columns () = struct
  type t = Idx of int
  let ops = ref [] and lhs = ref [] and rhs = ref []

  let add expr =
    let op, l, r =
      match expr with
      | Binary (op, Idx l, Idx r) -> (code op, l, r)
      | Literal num -> (0, num, 0)
    in
    ops := !ops @ [op]; lhs := !lhs @ [l]; rhs := !rhs @ [r];
    Idx (List.length !ops - 1)

  let get (Idx i) =
    match List.nth !ops i with
    | 0 -> Literal (List.nth !lhs i)
    | op -> Binary (op_of op, Idx (List.nth !lhs i), Idx (List.nth !rhs i))
end

(* Representation 2: a node is an index into one list of triples. *)
module Triples () = struct
  type t = Slot of int
  let triples = ref []

  let add expr =
    (match expr with
     | Binary (op, Slot l, Slot r) -> triples := !triples @ [code op; l; r]
     | Literal num -> triples := !triples @ [0; num; 0]);
    Slot (List.length !triples / 3 - 1)

  let get (Slot i) =
    let at k = List.nth !triples (3 * i + k) in
    match at 0 with
    | 0 -> Literal (at 1)
    | op -> Binary (op_of op, Slot (at 1), Slot (at 2))
end

implicit module A = Columns ()

let () =
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
  Printf.printf "%d\n" (interp e);
  (* `A` and `B` both match until the type of the result says which. *)
  (let implicit module B = Triples () in
   Printf.printf "%d\n" (interp (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) : B.t)));
  Printf.printf "%d\n" (interp e)
