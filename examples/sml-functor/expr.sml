(* An ML functor: the pool is a structure argument, applied once per pool. *)
datatype binop = Add | Sub | Mul | Div
datatype expr_ref = ExprRef of int
datatype expr = Binary of binop * expr_ref * expr_ref | Literal of int

functor Interp (P : sig val pool : expr list ref end) = struct
  fun add expr = (P.pool := !P.pool @ [expr]; ExprRef (length (!P.pool) - 1))
  fun get (ExprRef i) = List.nth (!P.pool, i)

  fun interp expr =
    case get expr of
      Binary (oper, lhs, rhs) =>
        let val l = interp lhs val r = interp rhs in
          case oper of
            Add => l + r
          | Sub => l - r
          | Mul => l * r
          | Div => if r = 0 then 0 else Int.quot (l, r)
        end
    | Literal num => num

  fun lit n = add (Literal n)
  fun bin (oper, l, r) = add (Binary (oper, l, r))
end

(* SML writes negative numbers with `~`. *)
fun show n = (if n < 0 then "-" ^ Int.toString (~n) else Int.toString n) ^ "\n"

structure A = Interp (struct val pool = ref [] end)
val e = A.bin (Div, A.bin (Mul, A.bin (Sub, A.lit 7, A.lit 10), A.lit 7), A.lit 2)
val () = print (show (A.interp e))
local
  structure B = Interp (struct val pool = ref [] end)
in
  val () = print (show (B.interp (B.bin (Div, B.bin (Add, B.lit 4, B.lit 4), B.bin (Sub, B.lit 4, B.lit 4)))))
end
val () = print (show (A.interp e))
