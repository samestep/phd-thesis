# A context variable, reset with a token after the inner scope.
from contextvars import ContextVar
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
    lhs: int
    rhs: int


@dataclass
class Literal:
    num: int


pool: ContextVar[list] = ContextVar("pool")


def add(expr):
    pool.get().append(expr)
    return len(pool.get()) - 1


def get(ref):
    return pool.get()[ref]


def interp(ref):
    match get(ref):
        case Binary(op, lhs, rhs):
            l, r = interp(lhs), interp(rhs)
            match op:
                case BinOp.ADD: return l + r
                case BinOp.SUB: return l - r
                case BinOp.MUL: return l * r
                case BinOp.DIV: return 0 if r == 0 else int(Fraction(l, r))
        case Literal(num):
            return num


def lit(n): return add(Literal(n))
def bin(op, l, r): return add(Binary(op, l, r))


pool.set([])
e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, lit(7), lit(10)), lit(7)), lit(2))
print(interp(e))
token = pool.set([])
print(interp(bin(BinOp.DIV, bin(BinOp.ADD, lit(4), lit(4)), bin(BinOp.SUB, lit(4), lit(4)))))
pool.reset(token)
print(interp(e))
