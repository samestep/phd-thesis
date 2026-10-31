// Odin's implicit `context`: assigning to it lasts until the end of the scope.
package main

import "core:fmt"

Bin_Op :: enum { Add, Sub, Mul, Div }
Expr_Ref :: distinct u32
Binary :: struct { op: Bin_Op, lhs, rhs: Expr_Ref }
Literal :: distinct i64
Expr :: union { Binary, Literal }
Expr_Pool :: [dynamic]Expr

pool :: proc() -> ^Expr_Pool { return (^Expr_Pool)(context.user_ptr) }

add :: proc(expr: Expr) -> Expr_Ref {
	append(pool(), expr)
	return Expr_Ref(len(pool()) - 1)
}

get :: proc(expr: Expr_Ref) -> Expr { return pool()[expr] }

interp :: proc(expr: Expr_Ref) -> i64 {
	switch e in get(expr) {
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

lit :: proc(n: i64) -> Expr_Ref { return add(Literal(n)) }
bin :: proc(op: Bin_Op, lhs, rhs: Expr_Ref) -> Expr_Ref { return add(Binary{op, lhs, rhs}) }

main :: proc() {
	a: Expr_Pool
	context.user_ptr = &a
	e := bin(.Div, bin(.Mul, bin(.Sub, lit(7), lit(10)), lit(7)), lit(2))
	fmt.println(interp(e))
	{
		b: Expr_Pool
		context.user_ptr = &b
		fmt.println(interp(bin(.Div, bin(.Add, lit(4), lit(4)), bin(.Sub, lit(4), lit(4)))))
	}
	fmt.println(interp(e))
}
