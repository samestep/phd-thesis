// Context parameters: the pool is an implicit argument resolved from the caller's context.
enum class BinOp { Add, Sub, Mul, Div }

@JvmInline value class ExprRef(val index: Int)

sealed interface Expr
data class Binary(val op: BinOp, val lhs: ExprRef, val rhs: ExprRef) : Expr
data class Literal(val num: Long) : Expr

class ExprPool {
    private val exprs = mutableListOf<Expr>()

    fun add(expr: Expr): ExprRef {
        exprs.add(expr)
        return ExprRef(exprs.size - 1)
    }

    fun get(expr: ExprRef): Expr = exprs[expr.index]
}

context(pool: ExprPool) fun interp(expr: ExprRef): Long = when (val e = pool.get(expr)) {
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

context(pool: ExprPool) fun num(n: Long) = pool.add(Literal(n))
context(pool: ExprPool) fun bin(op: BinOp, l: ExprRef, r: ExprRef) = pool.add(Binary(op, l, r))

fun main() {
    with(ExprPool()) {
        val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
        println(interp(e))
        with(ExprPool()) {
            println(interp(bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))))
        }
        println(interp(e))
    }
}
