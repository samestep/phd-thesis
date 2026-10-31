// Parametric polymorphism plus explicit overloading: `interp` is polymorphic
// in the index type, and each representation adds its own `add` and `get` to
// the procedure groups that the polymorphic procedures call.
package main

import "core:fmt"

Bin_Op :: enum i64 { Add = 1, Sub, Mul, Div } // 0 means a literal.
Binary :: struct($R: typeid) { op: Bin_Op, lhs, rhs: R }
Literal :: distinct i64
Expr :: union($R: typeid) { Binary(R), Literal }

add :: proc{columns_add, triples_add}
get :: proc{columns_get, triples_get}

interp :: proc(expr: $R) -> i64 {
	switch e in get(expr) {
	case Binary(R):
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

lit :: proc($R: typeid, n: i64) -> R { return add(Expr(R)(Literal(n))) }
bin :: proc(op: Bin_Op, lhs, rhs: $R) -> R { return add(Expr(R)(Binary(R){op, lhs, rhs})) }

node :: proc($R: typeid, op, lhs, rhs: i64) -> Expr(R) {
	if op == 0 do return Literal(lhs)
	return Binary(R){Bin_Op(op), R(lhs), R(rhs)}
}

row :: proc(expr: Expr($R)) -> [3]i64 {
	switch e in expr {
	case Binary(R): return {i64(e.op), i64(e.lhs), i64(e.rhs)}
	case Literal: return {0, i64(e), 0}
	}
	unreachable()
}

// Representation 1: a node is an index into parallel lists.
Idx :: distinct u32
Columns :: struct { ops, lhs, rhs: [dynamic]i64 }

columns :: proc() -> ^Columns { return (^Columns)(context.user_ptr) }

columns_add :: proc(expr: Expr(Idx)) -> Idx {
	c, r := columns(), row(expr)
	append(&c.ops, r[0]); append(&c.lhs, r[1]); append(&c.rhs, r[2])
	return Idx(len(c.ops) - 1)
}

columns_get :: proc(i: Idx) -> Expr(Idx) {
	c := columns()
	return node(Idx, c.ops[i], c.lhs[i], c.rhs[i])
}

// Representation 2: a node is an index into one list of triples.
Slot :: distinct u32
Triples :: [dynamic]i64

triples :: proc() -> ^Triples { return (^Triples)(context.user_ptr) }

triples_add :: proc(expr: Expr(Slot)) -> Slot {
	t, r := triples(), row(expr)
	append(t, ..r[:])
	return Slot(len(t) / 3 - 1)
}

triples_get :: proc(i: Slot) -> Expr(Slot) {
	t := triples()
	return node(Slot, t[3 * i], t[3 * i + 1], t[3 * i + 2])
}

main :: proc() {
	a: Columns
	context.user_ptr = &a
	e := bin(.Div, bin(.Mul, bin(.Sub, lit(Idx, 7), lit(Idx, 10)), lit(Idx, 7)), lit(Idx, 2))
	fmt.println(interp(e))
	{
		b: Triples
		context.user_ptr = &b
		fmt.println(interp(bin(.Div, bin(.Add, lit(Slot, 4), lit(Slot, 4)), bin(.Sub, lit(Slot, 4), lit(Slot, 4)))))
	}
	fmt.println(interp(e))
}
