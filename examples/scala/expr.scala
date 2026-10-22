// Context parameters (given/using): the pool is passed implicitly by type.
import scala.collection.mutable.ArrayBuffer

enum Node:
  case Lit(n: Long)
  case Add(l: Int, r: Int)
  case Mul(l: Int, r: Int)
import Node.*

type Pool = ArrayBuffer[Node]

def push(node: Node)(using pool: Pool): Int =
  pool += node
  pool.length - 1

def lit(n: Long)(using Pool) = push(Lit(n))
def add(l: Int, r: Int)(using Pool) = push(Add(l, r))
def mul(l: Int, r: Int)(using Pool) = push(Mul(l, r))

def eval(e: Int)(using pool: Pool): Long = pool(e) match
  case Lit(n) => n
  case Add(l, r) => eval(l) + eval(r)
  case Mul(l, r) => eval(l) * eval(r)

@main def run() =
  given Pool = ArrayBuffer()
  val e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
  println(eval(e))
  locally {
    given Pool = ArrayBuffer()
    println(eval(add(lit(4), lit(4))))
  }
  println(eval(e))
