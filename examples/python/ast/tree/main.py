# The tree Sampson starts from: each node holds references to its children,
# so nothing needs a pool, but every node is its own heap object.
from dataclasses import dataclass
from enum import Enum
from fractions import Fraction


class BinOp(Enum):
    ADD = "+"
    SUB = "-"
    MUL = "*"
    DIV = "/"


@dataclass
class Binary:
    op: BinOp
    lhs: "Expr"
    rhs: "Expr"


@dataclass
class Literal:
    num: int


Expr = Binary | Literal


def interp(expr):
    match expr:
        case Binary(op, lhs, rhs):
            l, r = interp(lhs), interp(rhs)
            match op:
                case BinOp.ADD: return l + r
                case BinOp.SUB: return l - r
                case BinOp.MUL: return l * r
                case BinOp.DIV: return 0 if r == 0 else int(Fraction(l, r))
        case Literal(num):
            return num


def lit(n): return Literal(n)
def bin(op, l, r): return Binary(op, l, r)


e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, lit(7), lit(10)), lit(7)), lit(2))
print(interp(e))
f = bin(BinOp.DIV, bin(BinOp.ADD, lit(4), lit(4)), bin(BinOp.SUB, lit(4), lit(4)))
print(interp(f))
print(interp(e))
