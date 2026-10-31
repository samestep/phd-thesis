// A context.Context carrying the pool, passed down explicitly.
package main

import (
	"context"
	"fmt"
)

type BinOp int

const (
	Add BinOp = iota
	Sub
	Mul
	Div
)

type ExprRef uint32

type Expr interface{ isExpr() }
type Binary struct {
	Op       BinOp
	Lhs, Rhs ExprRef
}
type Literal int64

func (Binary) isExpr()  {}
func (Literal) isExpr() {}

type ExprPool []Expr

type poolKey struct{}

func pool(ctx context.Context) *ExprPool { return ctx.Value(poolKey{}).(*ExprPool) }

func withPool(ctx context.Context) context.Context {
	return context.WithValue(ctx, poolKey{}, &ExprPool{})
}

func add(ctx context.Context, expr Expr) ExprRef {
	p := pool(ctx)
	*p = append(*p, expr)
	return ExprRef(len(*p) - 1)
}

func get(ctx context.Context, expr ExprRef) Expr { return (*pool(ctx))[expr] }

// Go's integer arithmetic wraps, and its division truncates.
func interp(ctx context.Context, expr ExprRef) int64 {
	switch e := get(ctx, expr).(type) {
	case Binary:
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
		return int64(e.(Literal))
	}
}

func lit(ctx context.Context, n int64) ExprRef { return add(ctx, Literal(n)) }
func bin(ctx context.Context, op BinOp, lhs, rhs ExprRef) ExprRef {
	return add(ctx, Binary{op, lhs, rhs})
}

func main() {
	ctx := withPool(context.Background())
	e := bin(ctx, Div, bin(ctx, Mul, bin(ctx, Sub, lit(ctx, 7), lit(ctx, 10)), lit(ctx, 7)), lit(ctx, 2))
	fmt.Println(interp(ctx, e))
	{
		ctx := withPool(ctx)
		fmt.Println(interp(ctx, bin(ctx, Div, bin(ctx, Add, lit(ctx, 4), lit(ctx, 4)), bin(ctx, Sub, lit(ctx, 4), lit(ctx, 4)))))
	}
	fmt.Println(interp(ctx, e))
}
