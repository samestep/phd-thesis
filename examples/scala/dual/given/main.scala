// A type parameter with a given type class: `Field[A]` has the arithmetic and
// the constants, a given makes `Field[Dual[A]]` from any `Field[A]`, so duals
// nest, and `Real[A]` adds rounding. Every function names `A` and its class
// in its signature (`[A: Field]`), though the compiler infers `A` at each
// call from the argument type and derives the given; a literal like `2.0` is
// always a `Double`, so `f` writes `constant(2.0)`, summoning the given at
// `A`. `Dual[Dual[A]]` and `Dual[A]` are different types, so `nested` has to
// lift the outer variable into the inner differentiation (`still(x)`):
// adding it as it is (`x + variable(y0)`) is a compile-time error, since the
// `+` for `Dual[A]` takes a `Dual[A]`. But givens are objects passed at run
// time, and the JVM erases `A` to `Object`: each value is boxed, and each
// operation is an interface call, unless the JIT inlines it and elides the
// boxes.
trait Field[A]:
  def constant(n: Double): A
  extension (x: A)
    def +(y: A): A
    def -(y: A): A
    def *(y: A): A
    def /(y: A): A

trait Real[A] extends Field[A]:
  extension (x: A) def round: Long

given Real[Double] with
  def constant(n: Double) = n
  extension (x: Double)
    def +(y: Double) = x + y
    def -(y: Double) = x - y
    def *(y: Double) = x * y
    def /(y: Double) = x / y
    def round = math.rint(x).toLong

def constant[A](n: Double)(using field: Field[A]): A = field.constant(n)

def f[A: Field](x: A): A = x * x * x - constant(2.0) * x - constant(5.0)

case class Dual[A](v: A, d: A)

def variable[A: Field](x: A): Dual[A] = Dual(x, constant(1.0))

def still[A: Field](x: A): Dual[A] = Dual(x, constant(0.0))

given [A: Field]: Field[Dual[A]] with
  def constant(n: Double) = still(summon[Field[A]].constant(n))
  extension (x: Dual[A])
    def +(y: Dual[A]) = Dual(x.v + y.v, x.d + y.d)
    def -(y: Dual[A]) = Dual(x.v - y.v, x.d - y.d)
    def *(y: Dual[A]) = Dual(x.v * y.v, x.d * y.v + x.v * y.d)
    def /(y: Dual[A]) =
      Dual(x.v / y.v, (x.d * y.v - x.v * y.d) / (y.v * y.v))

def show[A: Real](x: A): Unit = println((x * constant(1000000.0)).round)

def derivatives[A: Real](x: A): Unit =
  show(f(x))
  show(f(variable(x)).d)
  show(f(variable(variable(x))).d.d)

def newton[A: Real](x0: A, steps: Int): Unit =
  var x = x0
  for _ <- 0 until steps do
    val y = f(variable(x))
    x = x - y.v / y.d
    show(x)

// d/dx (x * d/dy (x + y)) at x = 1, y = 1.
def nested[A: Real](at: A): A =
  val x = variable(at)
  val y0 = constant[Dual[A]](1.0)
  val inner = (still(x) + variable(y0)).d
  (x * inner).d

@main def run(): Unit =
  derivatives(2.0)
  newton(2.0, 4)
  show(nested(1.0))
