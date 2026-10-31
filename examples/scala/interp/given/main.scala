// Context parameters over path-dependent types: the pool, the arithmetic and
// the tracer are each a given, and the index and value types are members,
// `pool.Ref` and `arith.Value`, so no function needs a type parameter, but
// every function lists the givens it uses in a leading `using` clause that
// names them, so that later types can depend on them. A `Traced` node shadows
// the tracer with a nested given. But givens are objects passed at run time,
// and the JVM erases the member types to `Object`: each value is boxed, and
// each operation, node and trace is an interface call, unless the JIT inlines
// it and elides the boxes, which it does only while a call site has seen few
// enough classes.
import scala.collection.mutable.ArrayBuffer

enum BinOp:
  case Add, Sub, Mul, Div

enum Expr[+R]:
  case Binary(op: BinOp, lhs: R, rhs: R)
  case Literal(n: Int) extends Expr[Nothing]
  // Evaluate the inner expression with tracing on.
  case Traced(inner: R)
import Expr.*

// The pool: an index type, how to read a node through one, and how to make
// one.
trait Pool:
  type Ref
  def node(e: Ref): Expr[Ref]
  def add(expr: Expr[Ref]): Ref

// The arithmetic of the interpreted language: what a value is, what a
// literal means, and how to print one.
trait Arith:
  type Value
  def value(n: Int): Value
  def printValue(v: Value): Unit
  extension (x: Value)
    def +(y: Value): Value
    def -(y: Value): Value
    def *(y: Value): Value
    def /(y: Value): Value

// Called with every intermediate value.
trait Trace:
  def trace(using arith: Arith)(v: arith.Value): Unit

object Quiet extends Trace:
  def trace(using arith: Arith)(v: arith.Value) = ()

object Loud extends Trace:
  def trace(using arith: Arith)(v: arith.Value) =
    print("  ")
    arith.printValue(v)

// Written once, against the traits alone.
def interp(using pool: Pool, arith: Arith, tracer: Trace)(e: pool.Ref): arith.Value =
  val v = pool.node(e) match
    case Binary(op, lhs, rhs) =>
      val l = interp(lhs)
      val r = interp(rhs)
      op match
        case BinOp.Add => l + r
        case BinOp.Sub => l - r
        case BinOp.Mul => l * r
        case BinOp.Div => l / r
    case Literal(n) => arith.value(n)
    case Traced(inner) =>
      given Trace = Loud
      interp(inner)
  tracer.trace(v)
  v

def report(using pool: Pool, arith: Arith, tracer: Trace)(e: pool.Ref) =
  arith.printValue(interp(e))

def lit(using pool: Pool)(n: Int): pool.Ref = pool.add(Literal(n))
def bin(using pool: Pool)(op: BinOp, lhs: pool.Ref, rhs: pool.Ref): pool.Ref =
  pool.add(Binary(op, lhs, rhs))
def traced(using pool: Pool)(inner: pool.Ref): pool.Ref = pool.add(Traced(inner))

// A pool: a node is an index into one list of triples.
case class Slot(index: Int)

class Triples extends Pool:
  type Ref = Slot
  private val triples = ArrayBuffer[Int]()
  def node(e: Slot): Expr[Slot] =
    val i = 3 * e.index
    val (code, a, b) = (triples(i), triples(i + 1), triples(i + 2))
    if code == 0 then Literal(a)
    else if code == 5 then Traced(Slot(a))
    else Binary(BinOp.fromOrdinal(code - 1), Slot(a), Slot(b))
  def add(expr: Expr[Slot]): Slot =
    val i = triples.length / 3
    triples ++= (expr match
      case Binary(op, lhs, rhs) => Seq(op.ordinal + 1, lhs.index, rhs.index)
      case Literal(n) => Seq(0, n, 0)
      case Traced(inner) => Seq(5, inner.index, 0))
    Slot(i)

// Three meanings for the interpreted language's arithmetic.
object Wrapping extends Arith:
  type Value = Int
  def value(n: Int) = n
  def printValue(v: Int) = println(v)
  extension (x: Int)
    def +(y: Int) = x + y
    def -(y: Int) = x - y
    def *(y: Int) = x * y
    def /(y: Int) = x / y

// Converting a Double to an Int truncates toward zero and saturates, and a
// Double holds every Int sum, difference and quotient exactly enough, and
// every product below 2^53.
object Saturating extends Arith:
  type Value = Int
  def value(n: Int) = n
  def printValue(v: Int) = println(v)
  extension (x: Int)
    def +(y: Int) = (x.toDouble + y.toDouble).toInt
    def -(y: Int) = (x.toDouble - y.toDouble).toInt
    def *(y: Int) = (x.toDouble * y.toDouble).toInt
    def /(y: Int) = (x.toDouble / y.toDouble).toInt

object Floating extends Arith:
  type Value = Double
  def value(n: Int) = n.toDouble
  // `rint` rounds ties to even.
  def printValue(v: Double) = println(math.rint(v).toInt)
  extension (x: Double)
    def +(y: Double) = x + y
    def -(y: Double) = x - y
    def *(y: Double) = x * y
    def /(y: Double) = x / y

@main def run() =
  given Pool = Triples()
  // 50000 * 50000 / 100000 + traced((7 - 10) * 7 / 8)
  val e = bin(BinOp.Add,
    bin(BinOp.Div, bin(BinOp.Mul, lit(50000), lit(50000)), lit(100000)),
    traced(bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, lit(7), lit(10)), lit(7)), lit(8))))
  locally {
    given Arith = Wrapping
    given Trace = Quiet
    report(e)
  }
  locally {
    given Arith = Saturating
    given Trace = Quiet
    report(e)
  }
  locally {
    given Arith = Floating
    given Trace = Quiet
    report(e)
  }
