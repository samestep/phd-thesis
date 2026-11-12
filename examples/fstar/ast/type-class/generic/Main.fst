(* Type classes: `{| ast pool ref |}` is a representation and `{| has_pool pool |}` the built
   pool, both filled by instance resolution. Resolution follows the pool type to the index type
   (a fundep) but not back, so the pool type is passed by hand wherever only an index is known. *)
module Main
open FStar.Tactics.V2
open FStar.List.Tot

type binop = | Add | Sub | Mul | Div
type expr (ref : Type) = | Binary : binop -> ref -> ref -> expr ref | Literal : int -> expr ref

[@@ FStar.Tactics.Typeclasses.fundeps [1]]
class ast (pool : Type) (ref : Type) = {
  add : expr ref -> pool -> pool & ref;
  get : pool -> ref -> expr ref;
}

class has_pool (pool : Type) = { the_pool : pool }

(* F*'s `/` is Euclidean; the post's division truncates toward zero, and gives 0 for 0. *)
let quot (l r : int) : int =
  if r = 0 then 0
  else let q = abs l / abs r in if (l < 0) <> (r < 0) then - q else q

let rec interp #pool #ref {| ast pool ref |} {| has_pool pool |} (fuel : nat) (e : ref)
  : Tot int (decreases fuel) =
  if fuel = 0 then 0 else
  match get #pool #ref the_pool e with
  | Binary op lhs rhs ->
    let l = interp #pool (fuel - 1) lhs in
    let r = interp #pool (fuel - 1) rhs in
    (match op with
     | Add -> l + r
     | Sub -> l - r
     | Mul -> l * r
     | Div -> quot l r)
  | Literal num -> num

(* Building threads the pool through; `interp` finds it by instance resolution. *)
type build (pool ref : Type) = pool -> pool & ref

let lit #pool #ref {| ast pool ref |} (n : int) : build pool ref = add (Literal n)
let bin #pool #ref {| ast pool ref |} op (l r : build pool ref) : build pool ref =
  fun p -> let (p1, x) = l p in let (p2, y) = r p1 in add (Binary op x y) p2

let code (op : binop) : int = match op with Add -> 1 | Sub -> 2 | Mul -> 3 | Div -> 4
let op_of (c : int) : binop = match c with 1 -> Add | 2 -> Sub | 3 -> Mul | _ -> Div

let rec nth (xs : list int) (i : nat) : int =
  match xs with
  | [] -> 0
  | x :: xs -> if i = 0 then x else nth xs (i - 1)

let to_nat (x : int) : nat = if x < 0 then 0 else x

(* Representation 1: a node is an index into parallel lists. *)
type idx = | Idx : nat -> idx
type columns = { ops : list int; lhs : list int; rhs : list int }

instance columns_ast : ast columns idx = {
  add = (fun e c ->
    let (op, l, r) : int & int & int = match e with
      | Binary op (Idx l) (Idx r) -> (code op, l, r)
      | Literal num -> (0, num, 0) in
    ({ ops = c.ops @ [op]; lhs = c.lhs @ [l]; rhs = c.rhs @ [r] }, Idx (length c.ops)));
  get = (fun c (Idx i) ->
    match nth c.ops i with
    | 0 -> Literal (nth c.lhs i)
    | op -> Binary (op_of op) (Idx (to_nat (nth c.lhs i))) (Idx (to_nat (nth c.rhs i))));
}

(* Representation 2: a node is an index into one list of triples. *)
type slot = | Slot : nat -> slot
type triples = | Triples : list int -> triples

instance triples_ast : ast triples slot = {
  add = (fun e (Triples t) ->
    let row = match e with
      | Binary op (Slot l) (Slot r) -> [code op; l; r]
      | Literal num -> [0; num; 0] in
    (Triples (t @ row), Slot (length t / 3)));
  get = (fun (Triples t) (Slot i) ->
    let cell (k : nat) = nth t (3 * i + k) in
    match cell 0 with
    | 0 -> Literal (cell 1)
    | op -> Binary (op_of op) (Slot (to_nat (cell 1))) (Slot (to_nat (cell 2))));
}

let a = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) { ops = []; lhs = []; rhs = [] }
let outer : int = let p : has_pool columns = { the_pool = fst a } in interp #columns 100 (snd a)
let b = bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) (Triples [])
let inner : int = let p : has_pool triples = { the_pool = fst b } in interp #triples 100 (snd b)

let show (t : term) : Tac unit = print (term_to_string (norm_term [delta; zeta; iota; primops] t))
let _ = assert True by (show (`outer); show (`inner); show (`outer); trivial ())
