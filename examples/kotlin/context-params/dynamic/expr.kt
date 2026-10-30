// Context parameters over a plain interface: the context is any `Ast`, with
// `ExprRef` fixed once for every representation, so the types no longer tell
// one pool's references from another's.
enum class BinOp { Add, Sub, Mul, Div }

@JvmInline value class ExprRef(val index: Int)

sealed interface Expr
data class Binary(val op: BinOp, val lhs: ExprRef, val rhs: ExprRef) : Expr
data class Literal(val num: Long) : Expr

interface Ast {
    fun add(expr: Expr): ExprRef
    fun get(expr: ExprRef): Expr
}

context(ast: Ast) fun interp(expr: ExprRef): Long = when (val e = ast.get(expr)) {
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

context(ast: Ast) fun num(n: Long) = ast.add(Literal(n))
context(ast: Ast) fun bin(op: BinOp, l: ExprRef, r: ExprRef) = ast.add(Binary(op, l, r))

// Operators are stored as codes: 0 is a literal, and BinOp n is n + 1.
fun node(op: Long, lhs: Long, rhs: Long): Expr =
    if (op == 0L) Literal(lhs) else Binary(BinOp.entries[op.toInt() - 1], ExprRef(lhs.toInt()), ExprRef(rhs.toInt()))

// Representation 1: a node is an index into parallel lists.
class Columns : Ast {
    private val ops = mutableListOf<Long>()
    private val lhs = mutableListOf<Long>()
    private val rhs = mutableListOf<Long>()

    override fun add(expr: Expr): ExprRef {
        when (expr) {
            is Binary -> { ops += expr.op.ordinal + 1L; lhs += expr.lhs.index.toLong(); rhs += expr.rhs.index.toLong() }
            is Literal -> { ops += 0L; lhs += expr.num; rhs += 0L }
        }
        return ExprRef(ops.size - 1)
    }

    override fun get(expr: ExprRef): Expr = node(ops[expr.index], lhs[expr.index], rhs[expr.index])
}

// Representation 2: a node is an index into one list of triples.
class Triples : Ast {
    private val triples = mutableListOf<Long>()

    override fun add(expr: Expr): ExprRef {
        triples += when (expr) {
            is Binary -> listOf(expr.op.ordinal + 1L, expr.lhs.index.toLong(), expr.rhs.index.toLong())
            is Literal -> listOf(0L, expr.num, 0L)
        }
        return ExprRef(triples.size / 3 - 1)
    }

    override fun get(expr: ExprRef): Expr {
        val i = 3 * expr.index
        return node(triples[i], triples[i + 1], triples[i + 2])
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
