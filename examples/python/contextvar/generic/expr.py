# Duck typing: the context variable holds any object with `add` and `get`,
# and its references can be anything at all.
from contextvars import ContextVar
from dataclasses import dataclass
from enum import Enum
from fractions import Fraction


class BinOp(Enum):
    ADD = 1
    SUB = 2
    MUL = 3
    DIV = 4


@dataclass
class Binary:
    op: BinOp
    lhs: object
    rhs: object


@dataclass
class Literal:
    num: int


ast: ContextVar = ContextVar("ast")


def interp(ref):
    match ast.get().get(ref):
        case Binary(op, lhs, rhs):
            l, r = interp(lhs), interp(rhs)
            match op:
                case BinOp.ADD: return l + r
                case BinOp.SUB: return l - r
                case BinOp.MUL: return l * r
                case BinOp.DIV: return 0 if r == 0 else int(Fraction(l, r))
        case Literal(num):
            return num


def lit(n): return ast.get().add(Literal(n))
def bin(op, l, r): return ast.get().add(Binary(op, l, r))


# Representation 1: a node is an index into parallel lists.
@dataclass(frozen=True)
class Idx:
    i: int


class Columns:
    def __init__(self):
        self.ops, self.lhs, self.rhs = [], [], []

    def add(self, expr):
        match expr:
            case Binary(op, Idx(l), Idx(r)): row = (op.value, l, r)
            case Literal(num): row = (0, num, 0)
        for column, x in zip((self.ops, self.lhs, self.rhs), row):
            column.append(x)
        return Idx(len(self.ops) - 1)

    def get(self, ref):
        i = ref.i
        if self.ops[i] == 0:
            return Literal(self.lhs[i])
        return Binary(BinOp(self.ops[i]), Idx(self.lhs[i]), Idx(self.rhs[i]))


# Representation 2: a node is an index into one list of triples.
@dataclass(frozen=True)
class Slot:
    i: int


class Triples:
    def __init__(self):
        self.triples = []

    def add(self, expr):
        match expr:
            case Binary(op, Slot(l), Slot(r)): self.triples += [op.value, l, r]
            case Literal(num): self.triples += [0, num, 0]
        return Slot(len(self.triples) // 3 - 1)

    def get(self, ref):
        op, l, r = self.triples[3 * ref.i : 3 * ref.i + 3]
        return Literal(l) if op == 0 else Binary(BinOp(op), Slot(l), Slot(r))


ast.set(Columns())
e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, lit(7), lit(10)), lit(7)), lit(2))
print(interp(e))
token = ast.set(Triples())
print(interp(bin(BinOp.DIV, bin(BinOp.ADD, lit(4), lit(4)), bin(BinOp.SUB, lit(4), lit(4)))))
ast.reset(token)
print(interp(e))
