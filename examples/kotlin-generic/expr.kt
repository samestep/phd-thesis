// Context parameters over a generic interface: the context is any `Ast<R>`,
// so every function that touches an `Expr` takes the index type as a type
// parameter, inferred from whichever `Ast` the context supplies.
enum class BinOp { Add, Sub, Mul, Div }

sealed interface Expr<out R>
data class Binary<R>(val op: BinOp, val lhs: R, val rhs: R) : Expr<R>
data class Literal(val num: Long) : Expr<Nothing>

interface Ast<R> {
    fun add(expr: Expr<R>): R
    fun get(expr: R): Expr<R>
}

context(ast: Ast<R>) fun <R> interp(expr: R): Long = when (val e = ast.get(expr)) {
    is Binary -> {
        val l = interp(e.lhs)
        val r = interp(e.rhs)
        when (e.op) {
            BinOp.Add -> l + r
            BinOp.Sub -> l - r
            BinOp.Mul -> l * r
            BinOp.Div -> if (r == 0L) 0 else l / r
        }
    }
    is Literal -> e.num
}

context(ast: Ast<R>) fun <R> num(n: Long): R = ast.add(Literal(n))
context(ast: Ast<R>) fun <R> bin(op: BinOp, l: R, r: R): R = ast.add(Binary(op, l, r))

// Operators are stored as codes: 0 is a literal, and BinOp n is n + 1.
fun <R> node(op: Long, lhs: Long, rhs: Long, ref: (Long) -> R): Expr<R> =
    if (op == 0L) Literal(lhs) else Binary(BinOp.entries[op.toInt() - 1], ref(lhs), ref(rhs))

// Representation 1: a node is an index into parallel lists.
@JvmInline value class Idx(val index: Int)

class Columns : Ast<Idx> {
    private val ops = mutableListOf<Long>()
    private val lhs = mutableListOf<Long>()
    private val rhs = mutableListOf<Long>()

    override fun add(expr: Expr<Idx>): Idx {
        when (expr) {
            is Binary -> { ops += expr.op.ordinal + 1L; lhs += expr.lhs.index.toLong(); rhs += expr.rhs.index.toLong() }
            is Literal -> { ops += 0L; lhs += expr.num; rhs += 0L }
        }
        return Idx(ops.size - 1)
    }

    override fun get(expr: Idx): Expr<Idx> =
        node(ops[expr.index], lhs[expr.index], rhs[expr.index]) { Idx(it.toInt()) }
}

// Representation 2: a node is an index into one list of triples.
@JvmInline value class Slot(val index: Int)

class Triples : Ast<Slot> {
    private val triples = mutableListOf<Long>()

    override fun add(expr: Expr<Slot>): Slot {
        triples += when (expr) {
            is Binary -> listOf(expr.op.ordinal + 1L, expr.lhs.index.toLong(), expr.rhs.index.toLong())
            is Literal -> listOf(0L, expr.num, 0L)
        }
        return Slot(triples.size / 3 - 1)
    }

    override fun get(expr: Slot): Expr<Slot> {
        val i = 3 * expr.index
        return node(triples[i], triples[i + 1], triples[i + 2]) { Slot(it.toInt()) }
    }
}

fun main() {
    with(Columns()) {
        val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
        println(interp(e))
        with(Triples()) {
            println(interp(bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))))
        }
        println(interp(e))
    }
}
