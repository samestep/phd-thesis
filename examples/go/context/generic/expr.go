// A generic interface: Ast[R] leaves the index type open, but the context only
// holds an `any`, so getting the pool back is a type assertion checked at run
// time, and `lit` can't infer R, so its callers name the index type.
package main

import (
	"context"
	"fmt"
)

type BinOp int

const (
	Add BinOp = iota + 1 // 0 means a literal.
	Sub
	Mul
	Div
)

type Expr[R any] interface{ isExpr(R) }
type Binary[R any] struct {
	Op       BinOp
	Lhs, Rhs R
}
type Literal[R any] int64

func (Binary[R]) isExpr(R)  {}
func (Literal[R]) isExpr(R) {}

type Ast[R any] interface {
	Add(expr Expr[R]) R
	Get(expr R) Expr[R]
}

type poolKey struct{}

func pool[R any](ctx context.Context) Ast[R] { return ctx.Value(poolKey{}).(Ast[R]) }

func withPool[R any](ctx context.Context, ast Ast[R]) context.Context {
	return context.WithValue(ctx, poolKey{}, ast)
}

// Go's integer arithmetic wraps, and its division truncates.
func interp[R any](ctx context.Context, expr R) int64 {
	switch e := pool[R](ctx).Get(expr).(type) {
	case Binary[R]:
		lhs, rhs := interp(ctx, e.Lhs), interp(ctx, e.Rhs)
		switch e.Op {
		case Add:
			return lhs + rhs
		case Sub:
			return lhs - rhs
		case Mul:
			return lhs * rhs
		default:
			if rhs == 0 {
				return 0
			}
			return lhs / rhs
		}
	default:
		return int64(e.(Literal[R]))
	}
}

func lit[R any](ctx context.Context, n int64) R { return pool[R](ctx).Add(Literal[R](n)) }
func bin[R any](ctx context.Context, op BinOp, lhs, rhs R) R {
	return pool[R](ctx).Add(Binary[R]{op, lhs, rhs})
}

func node[R ~uint32](op, lhs, rhs int64) Expr[R] {
	if op == 0 {
		return Literal[R](lhs)
	}
	return Binary[R]{BinOp(op), R(lhs), R(rhs)}
}

// Representation 1: a node is an index into parallel lists.
type Idx uint32

type Columns struct{ ops, lhs, rhs []int64 }

func (c *Columns) Add(expr Expr[Idx]) Idx {
	switch e := expr.(type) {
	case Binary[Idx]:
		c.ops, c.lhs, c.rhs = append(c.ops, int64(e.Op)), append(c.lhs, int64(e.Lhs)), append(c.rhs, int64(e.Rhs))
	case Literal[Idx]:
		c.ops, c.lhs, c.rhs = append(c.ops, 0), append(c.lhs, int64(e)), append(c.rhs, 0)
	}
	return Idx(len(c.ops) - 1)
}

func (c *Columns) Get(i Idx) Expr[Idx] { return node[Idx](c.ops[i], c.lhs[i], c.rhs[i]) }

// Representation 2: a node is an index into one list of triples.
type Slot uint32

type Triples []int64

func (t *Triples) Add(expr Expr[Slot]) Slot {
	switch e := expr.(type) {
	case Binary[Slot]:
		*t = append(*t, int64(e.Op), int64(e.Lhs), int64(e.Rhs))
	case Literal[Slot]:
		*t = append(*t, 0, int64(e), 0)
	}
	return Slot(len(*t)/3 - 1)
}

func (t *Triples) Get(i Slot) Expr[Slot] { return node[Slot]((*t)[3*i], (*t)[3*i+1], (*t)[3*i+2]) }

func main() {
	ctx := withPool[Idx](context.Background(), &Columns{})
	e := bin(ctx, Div, bin(ctx, Mul, bin(ctx, Sub, lit[Idx](ctx, 7), lit[Idx](ctx, 10)), lit[Idx](ctx, 7)), lit[Idx](ctx, 2))
	fmt.Println(interp(ctx, e))
	{
		ctx := withPool[Slot](ctx, &Triples{})
		fmt.Println(interp(ctx, bin(ctx, Div, bin(ctx, Add, lit[Slot](ctx, 4), lit[Slot](ctx, 4)), bin(ctx, Sub, lit[Slot](ctx, 4), lit[Slot](ctx, 4)))))
	}
	fmt.Println(interp(ctx, e))
}
