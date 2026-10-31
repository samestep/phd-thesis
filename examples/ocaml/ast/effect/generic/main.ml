(* OCaml 5 effect handlers: an effect can't leave a type for its handler to
   choose, so a functor declares the effects once per index type, and
   everything that performs them has to live inside that functor. *)
open Effect
open Effect.Deep

type binop = Add | Sub | Mul | Div
type 'r expr = Binary of binop * 'r * 'r | Literal of int

module Ast (R : sig type t end) = struct
  type _ Effect.t += Add_expr : R.t expr -> R.t Effect.t | Get_expr : R.t -> R.t expr Effect.t

  let add expr = perform (Add_expr expr)
  let get expr = perform (Get_expr expr)

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

  let handle (add : R.t expr -> R.t) (get : R.t -> R.t expr) f =
    try_with f ()
      { effc = fun (type a) (eff : a Effect.t) ->
          match eff with
          | Add_expr expr -> Some (fun (k : (a, _) continuation) -> continue k (add expr))
          | Get_expr r -> Some (fun (k : (a, _) continuation) -> continue k (get r))
          | _ -> None }
end

let code = function Add -> 1 | Sub -> 2 | Mul -> 3 | Div -> 4
let op_of = function 1 -> Add | 2 -> Sub | 3 -> Mul | _ -> Div

(* Representation 1: a node is an index into parallel lists. *)
type idx = Idx of int
module Columns = Ast (struct type t = idx end)

let with_columns f =
  let ops = Dynarray.create () and lhs = Dynarray.create () and rhs = Dynarray.create () in
  let add expr =
    let op, l, r =
      match expr with
      | Binary (op, Idx l, Idx r) -> (code op, l, r)
      | Literal num -> (0, num, 0)
    in
    Dynarray.add_last ops op; Dynarray.add_last lhs l; Dynarray.add_last rhs r;
    Idx (Dynarray.length ops - 1)
  and get (Idx i) =
    match Dynarray.get ops i with
    | 0 -> Literal (Dynarray.get lhs i)
    | op -> Binary (op_of op, Idx (Dynarray.get lhs i), Idx (Dynarray.get rhs i))
  in
  Columns.handle add get f

(* Representation 2: a node is an index into one list of triples. *)
type slot = Slot of int
module Triples = Ast (struct type t = slot end)

let with_triples f =
  let triples = Dynarray.create () in
  let add expr =
    (match expr with
     | Binary (op, Slot l, Slot r) -> Dynarray.append_list triples [code op; l; r]
     | Literal num -> Dynarray.append_list triples [0; num; 0]);
    Slot (Dynarray.length triples / 3 - 1)
  and get (Slot i) =
    let at k = Dynarray.get triples (3 * i + k) in
    match at 0 with
    | 0 -> Literal (at 1)
    | op -> Binary (op_of op, Slot (at 1), Slot (at 2))
  in
  Triples.handle add get f

let () =
  with_columns (fun () ->
      let open Columns in
      let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) in
      Printf.printf "%d\n" (interp e);
      with_triples (fun () ->
          let open Triples in
          Printf.printf "%d\n" (interp (bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)))));
      Printf.printf "%d\n" (interp e))
