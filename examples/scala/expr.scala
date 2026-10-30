// Context parameters (given/using): the pool is passed implicitly by type.
import scala.collection.mutable.ArrayBuffer

enum BinOp:
  case Add, Sub, Mul, Div

case class ExprRef(index: Int)

enum Expr:
  case Binary(op: BinOp, lhs: ExprRef, rhs: ExprRef)
  case Literal(num: Long)
import Expr.*

class ExprPool:
  private val exprs = ArrayBuffer[Expr]()
  def add(expr: Expr): ExprRef =
    exprs += expr
    ExprRef(exprs.length - 1)
  def get(expr: ExprRef): Expr = exprs(expr.index)

def interp(expr: ExprRef)(using pool: ExprPool): Long = pool.get(expr) match
  case Binary(op, lhs, rhs) =>
    val l = interp(lhs)
    val r = interp(rhs)
    op match
      case BinOp.Add => l + r
      case BinOp.Sub => l - r
      case BinOp.Mul => l * r
      case BinOp.Div => if r == 0 then 0 else l / r
  case Literal(num) => num

def num(n: Long)(using pool: ExprPool) = pool.add(Literal(n))
def bin(op: BinOp, l: ExprRef, r: ExprRef)(using pool: ExprPool) = pool.add(Binary(op, l, r))

@main def run() =
  given ExprPool = ExprPool()
  val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
  println(interp(e))
  locally {
    given ExprPool = ExprPool()
    println(interp(bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))))
  }
  println(interp(e))
