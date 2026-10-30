(* An ML functor over the representation: the index type is abstract in the
   signature, and each pool is a structure made by applying a functor. *)
datatype binop = Add | Sub | Mul | Div
datatype 'r expr = Binary of binop * 'r * 'r | Literal of int

signature AST = sig
  type t
  val add : t expr -> t
  val get : t -> t expr
end

functor Interp (A : AST) = struct
  fun interp expr =
    case A.get expr of
      Binary (oper, lhs, rhs) =>
        let val l = interp lhs val r = interp rhs in
          case oper of
            Add => l + r
          | Sub => l - r
          | Mul => l * r
          | Div => if r = 0 then 0 else Int.quot (l, r)
        end
    | Literal num => num

  fun lit n = A.add (Literal n)
  fun bin (oper, l, r) = A.add (Binary (oper, l, r))
end

fun code Add = 1 | code Sub = 2 | code Mul = 3 | code Div = 4
fun opOf 1 = Add | opOf 2 = Sub | opOf 3 = Mul | opOf _ = Div

(* Representation 1: a node is an index into parallel lists. *)
functor Columns () :> AST = struct
  datatype t = Idx of int
  val ops = ref [] and lhs = ref [] and rhs = ref []

  fun add expr =
    let
      val (oper, l, r) =
        case expr of
          Binary (oper, Idx l, Idx r) => (code oper, l, r)
        | Literal num => (0, num, 0)
    in
      ops := !ops @ [oper]; lhs := !lhs @ [l]; rhs := !rhs @ [r];
      Idx (length (!ops) - 1)
    end

  fun get (Idx i) =
    case List.nth (!ops, i) of
      0 => Literal (List.nth (!lhs, i))
    | oper => Binary (opOf oper, Idx (List.nth (!lhs, i)), Idx (List.nth (!rhs, i)))
end

(* Representation 2: a node is an index into one list of triples. *)
functor Triples () :> AST = struct
  datatype t = Slot of int
  val triples = ref []

  fun add expr =
    (case expr of
       Binary (oper, Slot l, Slot r) => triples := !triples @ [code oper, l, r]
     | Literal num => triples := !triples @ [0, num, 0];
     Slot (length (!triples) div 3 - 1))

  fun get (Slot i) =
    let fun at k = List.nth (!triples, 3 * i + k) in
      case at 0 of
        0 => Literal (at 1)
      | oper => Binary (opOf oper, Slot (at 1), Slot (at 2))
    end
end

(* SML writes negative numbers with `~`. *)
fun show n = (if n < 0 then "-" ^ Int.toString (~n) else Int.toString n) ^ "\n"

structure A = Interp (Columns ())
val e = A.bin (Div, A.bin (Mul, A.bin (Sub, A.lit 7, A.lit 10), A.lit 7), A.lit 2)
val () = print (show (A.interp e))
local
  structure B = Interp (Triples ())
in
  val () = print (show (B.interp (B.bin (Div, B.bin (Add, B.lit 4, B.lit 4), B.bin (Sub, B.lit 4, B.lit 4)))))
end
val () = print (show (A.interp e))
