// Odin's implicit `context`: assigning to it lasts until the end of the scope.
package main

import "core:fmt"

Op :: enum { Lit, Add, Mul }
Node :: struct { op: Op, a, b: int }
Pool :: [dynamic]Node

pool :: proc() -> ^Pool { return (^Pool)(context.user_ptr) }

push :: proc(op: Op, a, b: int) -> int {
	append(pool(), Node{op, a, b})
	return len(pool()) - 1
}

lit :: proc(n: int) -> int { return push(.Lit, n, 0) }
add :: proc(l, r: int) -> int { return push(.Add, l, r) }
mul :: proc(l, r: int) -> int { return push(.Mul, l, r) }

eval :: proc(e: int) -> int {
	n := pool()[e]
	switch n.op {
	case .Lit: return n.a
	case .Add: return eval(n.a) + eval(n.b)
	case .Mul: return eval(n.a) * eval(n.b)
	}
	unreachable()
}

main :: proc() {
	a: Pool
	context.user_ptr = &a
	e := mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
	fmt.println(eval(e))
	{
		b: Pool
		context.user_ptr = &b
		fmt.println(eval(add(lit(4), lit(4))))
	}
	fmt.println(eval(e))
}
