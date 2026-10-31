// Type parameters with a given type class for each choice, so the kernel
// names both types and both givens, and constants are members of the compute
// class. A `ClassTag` makes the storage a packed `Array[Float]` or
// `Array[Double]`, but the JVM erases `C` and `S` to `Object`: each element is
// boxed on its way into and out of the array, and each operation is an
// interface call on boxes, unless the JIT inlines them and elides the boxes.
import scala.collection.mutable.ArrayBuilder
import scala.reflect.ClassTag

trait Compute[C]:
  def zero: C
  def tenth: C
  def thousand: C
  extension (x: C)
    def +(y: C): C
    def *(y: C): C
    def round: Long

given Compute[Double] with
  def zero = 0.0
  def tenth = 0.1
  def thousand = 1000.0
  extension (x: Double)
    def +(y: Double) = x + y
    def *(y: Double) = x * y
    def round = math.rint(x).toLong

given Compute[Float] with
  def zero = 0.0f
  def tenth = 0.1f
  def thousand = 1000.0f
  extension (x: Float)
    def +(y: Float) = x + y
    def *(y: Float) = x * y
    def round = math.rint(x).toLong

trait Storage[C, S]:
  def narrow(x: C): S
  def widen(x: S): C

given [C]: Storage[C, C] with
  def narrow(x: C) = x
  def widen(x: C) = x

given Storage[Double, Float] with
  def narrow(x: Double) = x.toFloat
  def widen(x: Float) = x.toDouble

def report[C, S: ClassTag](n: Int)(using c: Compute[C], s: Storage[C, S]) =
  val builder = ArrayBuilder.make[S]
  for _ <- 0 until n do builder += s.narrow(c.tenth)
  val list = builder.result()
  var sum = c.zero
  for x <- list do sum = sum + s.widen(x)
  println((sum * c.thousand).round)

@main def run() =
  // Compute in f64, store in f64.
  report[Double, Double](1000000)
  // Compute in f64, store in f32: half the memory.
  report[Double, Float](1000000)
  // Compute in f32, store in f32.
  report[Float, Float](1000000)
