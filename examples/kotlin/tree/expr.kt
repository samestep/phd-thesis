// The tree Sampson starts from: each node holds references to its children,
// so nothing needs a pool, and the GC reclaims nodes nobody points to.
enum class BinOp { Add, Sub, Mul, Div }

sealed interface Expr
data class Binary(val op: BinOp, val lhs: Expr, val rhs: Expr) : Expr
data class Literal(val num: Long) : Expr

fun interp(expr: Expr): Long = when (expr) {
    is Binary -> {
        val l = interp(expr.lhs)
        val r = interp(expr.rhs)
        when (expr.op) {
            BinOp.Add -> l + r
            BinOp.Sub -> l - r
            BinOp.Mul -> l * r
            BinOp.Div -> if (r == 0L) 0 else l / r
        }
    }
    is Literal -> expr.num
}

fun num(n: Long): Expr = Literal(n)
fun bin(op: BinOp, l: Expr, r: Expr): Expr = Binary(op, l, r)

fun main() {
    val e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, num(7), num(10)), num(7)), num(2))
    println(interp(e))
    run {
        val f = bin(BinOp.Div, bin(BinOp.Add, num(4), num(4)), bin(BinOp.Sub, num(4), num(4)))
        println(interp(f))
    }
    println(interp(e))
}
