(* A functor over the representation: the index type is abstract in the
   signature, and each pool is a module made by a generative functor. *)
type binop = Add | Sub | Mul | Div
type 'r expr = Binary of binop * 'r * 'r | Literal of int

module type AST = sig
  type t
  val add : t expr -> t
  val get : t -> t expr
end

module Interp (A : AST) = struct
  let rec interp expr =
    match A.get expr with
    | Binary (op, lhs, rhs) ->
        let l = interp lhs and r = interp rhs in
        (match op with
         | Add -> l + r
         | Sub -> l - r
         | Mul -> l * r
         | Div -> if r = 0 then 0 else l / r)
    | Literal num -> num

  let lit n = A.add (Literal n)
  let bin op l r = A.add (Binary (op, l, r))
end

let code = function Add -> 1 | Sub -> 2 | Mul -> 3 | Div -> 4
let op_of = function 1 -> Add | 2 -> Sub | 3 -> Mul | _ -> Div

(* Representation 1: a node is an index into parallel lists. *)
module Columns () : AST = struct
  type t = Idx of int
  let ops = Dynarray.create () and lhs = Dynarray.create () and rhs = Dynarray.create ()

  let add expr =
    let op, l, r =
      match expr with
      | Binary (op, Idx l, Idx r) -> (code op, l, r)
      | Literal num -> (0, num, 0)
    in
    Dynarray.add_last ops op; Dynarray.add_last lhs l; Dynarray.add_last rhs r;
    Idx (Dynarray.length ops - 1)

  let get (Idx i) =
    match Dynarray.get ops i with
    | 0 -> Literal (Dynarray.get lhs i)
    | op -> Binary (op_of op, Idx (Dynarray.get lhs i), Idx (Dynarray.get rhs i))
end

(* Representation 2: a node is an index into one list of triples. *)
module Triples () : AST = struct
  type t = Slot of int
  let triples = Dynarray.create ()

  let add expr =
    (match expr with
     | Binary (op, Slot l, Slot r) -> Dynarray.append_list triples [code op; l; r]
     | Literal num -> Dynarray.append_list triples [0; num; 0]);
    Slot (Dynarray.length triples / 3 - 1)

  let get (Slot i) =
    let at k = Dynarray.get triples (3 * i + k) in
    match at 0 with
    | 0 -> Literal (at 1)
    | op -> Binary (op_of op, Slot (at 1), Slot (at 2))
end

let () =
  let module A = Columns () in
  let open Interp (A) in
  let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
  Printf.printf "%d\n" (interp e);
  (let module B = Triples () in
   let open Interp (B) in
   Printf.printf "%d\n" (interp (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)))));
  Printf.printf "%d\n" (interp e)
