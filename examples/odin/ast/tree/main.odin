// The tree Sampson starts from: each node points to its children, so nothing
// needs a pool, but every node is its own allocation and must be freed.
package main

import "core:fmt"

Bin_Op :: enum { Add, Sub, Mul, Div }
Binary :: struct { op: Bin_Op, lhs, rhs: ^Expr }
Literal :: distinct i64
Expr :: union { Binary, Literal }

destroy :: proc(expr: ^Expr) {
	if e, ok := expr.(Binary); ok {
		destroy(e.lhs)
		destroy(e.rhs)
	}
	free(expr)
}

interp :: proc(expr: ^Expr) -> i64 {
	switch e in expr {
	case Binary:
		// Odin's integer arithmetic wraps.
		lhs, rhs := interp(e.lhs), interp(e.rhs)
		switch e.op {
		case .Add: return lhs + rhs
		case .Sub: return lhs - rhs
		case .Mul: return lhs * rhs
		case .Div: return rhs == 0 ? 0 : lhs / rhs
		}
	case Literal:
		return i64(e)
	}
	unreachable()
}

lit :: proc(n: i64) -> ^Expr { return new_clone(Expr(Literal(n))) }
bin :: proc(op: Bin_Op, lhs, rhs: ^Expr) -> ^Expr { return new_clone(Expr(Binary{op, lhs, rhs})) }

main :: proc() {
	e := bin(.Div, bin(.Mul, bin(.Sub, lit(7), lit(10)), lit(7)), lit(2))
	defer destroy(e)
	fmt.println(interp(e))
	{
		f := bin(.Div, bin(.Add, lit(4), lit(4)), bin(.Sub, lit(4), lit(4)))
		defer destroy(f)
		fmt.println(interp(f))
	}
	fmt.println(interp(e))
}
