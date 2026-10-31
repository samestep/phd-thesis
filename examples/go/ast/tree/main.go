// The tree Sampson starts from: each node points to its children, so nothing
// needs a pool, but every node is its own allocation for the garbage collector.
package main

import "fmt"

type BinOp int

const (
	Add BinOp = iota
	Sub
	Mul
	Div
)

type Expr interface{ isExpr() }
type Binary struct {
	Op       BinOp
	Lhs, Rhs Expr
}
type Literal int64

func (*Binary) isExpr() {}
func (Literal) isExpr() {}

// Go's integer arithmetic wraps, and its division truncates.
func interp(expr Expr) int64 {
	switch e := expr.(type) {
	case *Binary:
		lhs, rhs := interp(e.Lhs), interp(e.Rhs)
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

func lit(n int64) Expr                 { return Literal(n) }
func bin(op BinOp, lhs, rhs Expr) Expr { return &Binary{op, lhs, rhs} }

func main() {
	e := bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
	fmt.Println(interp(e))
	{
		f := bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))
		fmt.Println(interp(f))
	}
	fmt.Println(interp(e))
}
