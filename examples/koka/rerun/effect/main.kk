// An effect for real arithmetic, whose handler chooses the type: `sd` and
// `report` say only that they need `real<a>`, and a caller's `with plain`
// or `with double-double` fixes `a` for everything called inside it, by
// handler scope, with nothing passed down by hand. `+`, `*` and the rest
// are overloaded at `a` to perform the effect's operations, so the
// routine reads as arithmetic, but Koka has no overloaded literals, so
// each literal is an operation too (`lit(100000002, 1)`, 10000000.2), and
// the handlers have to name the built-in operators they mean
// (`float64/(+)`), as must any code in this module adding two `int`s.
// The double-double is Koka's own `std/num/ddouble`. Lifting the f64
// readings is `.ddouble`, exact. Nothing is specialized: Koka compiles
// one copy of `sd`, over boxed values, and every `+` in it looks up the
// handler in the evidence vector and calls its clause through a function
// pointer.
import std/num/float64
import std/num/ddouble

effect real<a>
  fun lit(m : int, k : int) : a // m / 10^k
  fun add(x : a, y : a) : a
  fun sub(x : a, y : a) : a
  fun mul(x : a, y : a) : a
  fun quot(x : a, y : a) : a
  fun at-most(x : a, y : a) : bool
  fun root(x : a) : a
  fun nearest(x : a) : int

fun real/(+)(x : a, y : a) : real<a> a
  add(x, y)

fun real/(-)(x : a, y : a) : real<a> a
  sub(x, y)

fun real/(*)(x : a, y : a) : real<a> a
  mul(x, y)

fun real/(/)(x : a, y : a) : real<a> a
  quot(x, y)

fun real/(<=)(x : a, y : a) : real<a> bool
  at-most(x, y)

fun real/sqrt(x : a) : real<a> a
  root(x)

// NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
fun readings() : real<a> list<a>
  Cons(lit(100000002, 1), list(1, 1000).map(fn(i) if i % 2 == 1 then lit(100000001, 1) else lit(100000003, 1)))

// The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
// until version 12, clamp included.
fun sd(xs : list<a>) : real<a> a
  sums(xs, lit(0, 0), lit(0, 0), lit(0, 0))

fun sums(xs : list<a>, n : a, sum : a, sum-sq : a) : real<a> a
  match xs
    Cons(x, rest) -> sums(rest, n + lit(1, 0), sum + x, sum-sq + x * x)
    Nil ->
      val numerator = n * sum-sq - sum * sum
      if numerator <= lit(0, 0) then lit(0, 0) else sqrt(numerator / (n * (n - lit(1, 0))))

fun show-sd(sd : a) : <real<a>, console> ()
  println(nearest(sd * lit(1000000000, 0)))

fun report() : <real<a>, console> ()
  show-sd(sd(readings()))

fun plain(action : () -> <real<float64>|e> b) : e b
  with handler
    fun lit(m, k) float64/(/)(m.float64, pow(10, k).float64)
    fun add(x, y) float64/(+)(x, y)
    fun sub(x, y) float64/(-)(x, y)
    fun mul(x, y) float64/(*)(x, y)
    fun quot(x, y) float64/(/)(x, y)
    fun at-most(x, y) float64/(<=)(x, y)
    fun root(x) float64/sqrt(x)
    fun nearest(x) float64/round(x).int
  action()

fun double-double(action : () -> <real<ddouble>|e> b) : e b
  with handler
    fun lit(m, k) ddouble/(/)(m.ddouble, pow(10, k).ddouble)
    fun add(x, y) ddouble/(+)(x, y)
    fun sub(x, y) ddouble/(-)(x, y)
    fun mul(x, y) ddouble/(*)(x, y)
    fun quot(x, y) ddouble/(/)(x, y)
    fun at-most(x, y) ddouble/(<=)(x, y)
    fun root(x) ddouble/sqrt(x)
    fun nearest(x) ddouble/round(x).int
  action()

pub fun main()
  plain(report)
  val xs = plain(readings)
  double-double { show-sd(sd(xs.map(ddouble))) }
  double-double(report)
