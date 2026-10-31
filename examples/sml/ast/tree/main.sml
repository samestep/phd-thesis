(* The tree Sampson starts from: each node holds its children directly, and
   the garbage collector frees them, so nothing needs a pool. *)
datatype binop = Add | Sub | Mul | Div
datatype expr = Binary of binop * expr * expr | Literal of int

fun interp (Binary (oper, lhs, rhs)) =
      let val l = interp lhs val r = interp rhs in
        case oper of
          Add => l + r
        | Sub => l - r
        | Mul => l * r
        | Div => if r = 0 then 0 else Int.quot (l, r)
      end
  | interp (Literal num) = num

fun lit n = Literal n
fun bin (oper, l, r) = Binary (oper, l, r)

(* SML writes negative numbers with `~`. *)
fun show n = (if n < 0 then "-" ^ Int.toString (~n) else Int.toString n) ^ "\n"

val e = bin (Div, bin (Mul, bin (Sub, lit 7, lit 10), lit 7), lit 2)
val () = print (show (interp e))
local
  val f = bin (Div, bin (Add, lit 4, lit 4), bin (Sub, lit 4, lit 4))
in
  val () = print (show (interp f))
end
val () = print (show (interp e))
