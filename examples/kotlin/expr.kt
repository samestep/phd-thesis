// Context parameters: the pool is an implicit argument resolved from the caller's context.
sealed interface Node
data class Lit(val n: Long) : Node
data class Add(val l: Int, val r: Int) : Node
data class Mul(val l: Int, val r: Int) : Node

class Pool(val nodes: MutableList<Node> = mutableListOf())

context(pool: Pool) fun push(node: Node): Int {
    pool.nodes.add(node)
    return pool.nodes.size - 1
}

context(_: Pool) fun lit(n: Long) = push(Lit(n))
context(_: Pool) fun add(l: Int, r: Int) = push(Add(l, r))
context(_: Pool) fun mul(l: Int, r: Int) = push(Mul(l, r))

context(pool: Pool) fun eval(e: Int): Long = when (val node = pool.nodes[e]) {
    is Lit -> node.n
    is Add -> eval(node.l) + eval(node.r)
    is Mul -> eval(node.l) * eval(node.r)
}

fun main() {
    with(Pool()) {
        val e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
        println(eval(e))
        with(Pool()) {
            println(eval(add(lit(4), lit(4))))
        }
        println(eval(e))
    }
}
