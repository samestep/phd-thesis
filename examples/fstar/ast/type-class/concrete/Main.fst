(* Type classes: `{| expr_pool |}` is filled by instance resolution from the context. *)
module Main
open FStar.Tactics.V2
open FStar.List.Tot

type binop = | Add | Sub | Mul | Div
type expr_ref = | ExprRef : nat -> expr_ref
type expr = | Binary : binop -> expr_ref -> expr_ref -> expr | Literal : int -> expr

class expr_pool = { exprs : list expr }

let rec nth (es : list expr) (i : nat) : expr =
  match es with
  | [] -> Literal 0
  | e :: es -> if i = 0 then e else nth es (i - 1)

let get {| expr_pool |} (e : expr_ref) : expr = match e with ExprRef i -> nth exprs i

(* F*'s `/` is Euclidean; the post's division truncates toward zero, and gives 0 for 0. *)
let quot (l r : int) : int =
  if r = 0 then 0
  else let q = abs l / abs r in if (l < 0) <> (r < 0) then - q else q

let rec interp {| expr_pool |} (fuel : nat) (e : expr_ref) : Tot int (decreases fuel) =
  if fuel = 0 then 0 else
  match get e with
  | Binary op lhs rhs ->
    let l = interp (fuel - 1) lhs in
    let r = interp (fuel - 1) rhs in
    (match op with
     | Add -> l + r
     | Sub -> l - r
     | Mul -> l `op_Multiply` r
     | Div -> quot l r)
  | Literal num -> num

(* Building threads the pool through; `interp` finds it by instance resolution. *)
type build = list expr -> list expr & expr_ref

let add (e : expr) : build = fun es -> (es @ [e], ExprRef (length es))
let lit n = add (Literal n)
let bin op (l r : build) : build = fun es -> let (es1, x) = l es in let (es2, y) = r es1 in add (Binary op x y) es2

let a = bin Div (bin Mul (bin Sub (lit 7) (lit 10)) (lit 7)) (lit 2) []
let outer : int = let p : expr_pool = { exprs = fst a } in interp 100 (snd a)
let b = bin Div (bin Add (lit 4) (lit 4)) (bin Sub (lit 4) (lit 4)) []
let inner : int = let p : expr_pool = { exprs = fst b } in interp 100 (snd b)

let show (t : term) : Tac unit = print (term_to_string (norm_term [delta; zeta; iota; primops] t))
let _ = assert True by (show (`outer); show (`inner); show (`outer); trivial ())
