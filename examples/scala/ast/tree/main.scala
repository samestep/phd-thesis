// The tree Sampson starts from: each case holds references to its children,
// so nothing needs a pool, and the GC reclaims nodes nobody points to.
enum BinOp:
  case Add, Sub, Mul, Div

enum Expr:
  case Binary(op: BinOp, lhs: Expr, rhs: Expr)
  case Literal(num: Long)
import Expr.*

def interp(expr: Expr): Long = expr match
  case Binary(op, lhs, rhs) =>
    val l = interp(lhs)
    val r = interp(rhs)
    op match
      case BinOp.Add => l + r
      case BinOp.Sub => l - r
      case BinOp.Mul => l * r
      case BinOp.Div => if r == 0 then 0 else l / r
  case Literal(num) => num

def num(n: Long): Expr = Literal(n)
def bin(op: BinOp, l: Expr, r: Expr): Expr = Binary(op, l, r)

@main def run() =
  val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
  println(interp(e))
  locally {
    val f = bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))
    println(interp(f))
  }
  println(interp(e))
