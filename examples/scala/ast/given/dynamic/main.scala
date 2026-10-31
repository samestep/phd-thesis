// Context parameters over a plain trait: the given is any `Ast`, with
// `ExprRef` fixed once for every representation, so the types no longer tell
// one pool's references from another's.
import scala.collection.mutable.ArrayBuffer

enum BinOp:
  case Add, Sub, Mul, Div

case class ExprRef(index: Int)

enum Expr:
  case Binary(op: BinOp, lhs: ExprRef, rhs: ExprRef)
  case Literal(num: Long)
import Expr.*

trait Ast:
  def add(expr: Expr): ExprRef
  def get(expr: ExprRef): Expr

def interp(expr: ExprRef)(using ast: Ast): Long = ast.get(expr) match
  case Binary(op, lhs, rhs) =>
    val l = interp(lhs)
    val r = interp(rhs)
    op match
      case BinOp.Add => l + r
      case BinOp.Sub => l - r
      case BinOp.Mul => l * r
      case BinOp.Div => if r == 0 then 0 else l / r
  case Literal(num) => num

def num(n: Long)(using ast: Ast) = ast.add(Literal(n))
def bin(op: BinOp, l: ExprRef, r: ExprRef)(using ast: Ast) = ast.add(Binary(op, l, r))

// Operators are stored as codes: 0 is a literal, and BinOp n is n + 1.
def node(op: Long, lhs: Long, rhs: Long): Expr =
  if op == 0 then Literal(lhs)
  else Binary(BinOp.fromOrdinal(op.toInt - 1), ExprRef(lhs.toInt), ExprRef(rhs.toInt))

// Representation 1: a node is an index into parallel lists.
class Columns extends Ast:
  private val ops, lhs, rhs = ArrayBuffer[Long]()
  def add(expr: Expr): ExprRef =
    expr match
      case Binary(op, l, r) => ops += op.ordinal + 1; lhs += l.index; rhs += r.index
      case Literal(num) => ops += 0; lhs += num; rhs += 0
    ExprRef(ops.length - 1)
  def get(expr: ExprRef): Expr =
    val i = expr.index
    node(ops(i), lhs(i), rhs(i))

// Representation 2: a node is an index into one list of triples.
class Triples extends Ast:
  private val triples = ArrayBuffer[Long]()
  def add(expr: Expr): ExprRef =
    triples ++= (expr match
      case Binary(op, l, r) => Seq(op.ordinal + 1, l.index, r.index)
      case Literal(num) => Seq(0, num, 0))
    ExprRef(triples.length / 3 - 1)
  def get(expr: ExprRef): Expr =
    val i = 3 * expr.index
    node(triples(i), triples(i + 1), triples(i + 2))

@main def run() =
  given Ast = Columns()
  val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
  println(interp(e))
  locally {
    given Ast = Triples()
    println(interp(bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))))
  }
  println(interp(e))
