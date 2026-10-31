// Context parameters over a path-dependent type: the given is any `Ast`, and
// its index type is a member, `ast.Ref`, so no function needs a type
// parameter, and each given's `Ref` is its own type, so a reference from one
// pool can't be used with another. The price is a leading `using` clause that
// names the given, so that later parameters' types can depend on it.
import scala.collection.mutable.ArrayBuffer

enum BinOp:
  case Add, Sub, Mul, Div

enum Expr[+R]:
  case Binary(op: BinOp, lhs: R, rhs: R)
  case Literal(num: Long) extends Expr[Nothing]
import Expr.*

trait Ast:
  type Ref
  def add(expr: Expr[Ref]): Ref
  def get(expr: Ref): Expr[Ref]

def interp(using ast: Ast)(expr: ast.Ref): Long = ast.get(expr) match
  case Binary(op, lhs, rhs) =>
    val l = interp(lhs)
    val r = interp(rhs)
    op match
      case BinOp.Add => l + r
      case BinOp.Sub => l - r
      case BinOp.Mul => l * r
      case BinOp.Div => if r == 0 then 0 else l / r
  case Literal(num) => num

def num(using ast: Ast)(n: Long): ast.Ref = ast.add(Literal(n))
def bin(using ast: Ast)(op: BinOp, l: ast.Ref, r: ast.Ref): ast.Ref = ast.add(Binary(op, l, r))

// Operators are stored as codes: 0 is a literal, and BinOp n is n + 1.
def node[R](op: Long, lhs: Long, rhs: Long, ref: Long => R): Expr[R] =
  if op == 0 then Literal(lhs) else Binary(BinOp.fromOrdinal(op.toInt - 1), ref(lhs), ref(rhs))

// Representation 1: a node is an index into parallel lists.
case class Idx(index: Int)

class Columns extends Ast:
  type Ref = Idx
  private val ops, lhs, rhs = ArrayBuffer[Long]()
  def add(expr: Expr[Idx]): Idx =
    expr match
      case Binary(op, l, r) => ops += op.ordinal + 1; lhs += l.index; rhs += r.index
      case Literal(num) => ops += 0; lhs += num; rhs += 0
    Idx(ops.length - 1)
  def get(expr: Idx): Expr[Idx] =
    val i = expr.index
    node(ops(i), lhs(i), rhs(i), n => Idx(n.toInt))

// Representation 2: a node is an index into one list of triples.
case class Slot(index: Int)

class Triples extends Ast:
  type Ref = Slot
  private val triples = ArrayBuffer[Long]()
  def add(expr: Expr[Slot]): Slot =
    triples ++= (expr match
      case Binary(op, l, r) => Seq(op.ordinal + 1, l.index, r.index)
      case Literal(num) => Seq(0, num, 0))
    Slot(triples.length / 3 - 1)
  def get(expr: Slot): Expr[Slot] =
    val i = 3 * expr.index
    node(triples(i), triples(i + 1), triples(i + 2), n => Slot(n.toInt))

@main def run() =
  given Ast = Columns()
  val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
  println(interp(e))
  locally {
    given Ast = Triples()
    println(interp(bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))))
  }
  println(interp(e))
