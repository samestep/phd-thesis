(* An ML functor: the pool is a structure argument, applied once per pool. *)
datatype node = Lit of int | Add of int * int | Mul of int * int

functor Expr (P : sig val pool : node list ref end) = struct
  fun node n = (P.pool := !P.pool @ [n]; length (!P.pool) - 1)
  fun lit n = node (Lit n)
  fun add (l, r) = node (Add (l, r))
  fun mul (l, r) = node (Mul (l, r))

  fun eval e =
    case List.nth (!P.pool, e) of
      Lit n => n
    | Add (l, r) => eval l + eval r
    | Mul (l, r) => eval l * eval r
end

structure A = Expr (struct val pool = ref [] end)
val e = A.mul (A.add (A.lit 1, A.lit 2), A.add (A.lit 3, A.lit 4))
val () = print (Int.toString (A.eval e) ^ "\n")
local
  structure B = Expr (struct val pool = ref [] end)
in
  val () = print (Int.toString (B.eval (B.add (B.lit 4, B.lit 4))) ^ "\n")
end
val () = print (Int.toString (A.eval e) ^ "\n")
