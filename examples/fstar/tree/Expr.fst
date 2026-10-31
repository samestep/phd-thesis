(* The tree Sampson starts from: each node holds its children as nested values
   of an inductive type, so nothing needs a pool and `interp` needs no fuel. *)
module Expr
open FStar.Tactics.V2

type binop = | Add | Sub | Mul | Div
type expr = | Binary : binop -> expr -> expr -> expr | Literal : int -> expr

(* F*'s `/` is Euclidean; the post's division truncates toward zero, and gives 0 for 0. *)
let quot (l r : int) : int =
  if r = 0 then 0
  else let q = abs l / abs r in if (l < 0) <> (r < 0) then - q else q

let rec interp (e : expr) : int =
  match e with
  | Binary op lhs rhs ->
    let l = interp lhs in
    let r = interp rhs in
    (match op with
     | Add -> l + r
     | Sub -> l - r
     | Mul -> l `op_Multiply` r
     | Div -> quot l r)
  | Literal num -> num

let lit n = Literal n
let bin op l r = Binary op l r

let e = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2)
let outer : int = interp e
let inner : int = let f = bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) in interp f

let show (t : term) : Tac unit = print (term_to_string (norm_term [delta; zeta; iota; primops] t))
let _ = assert True by (show (`outer); show (`inner); show (`outer); trivial ())
