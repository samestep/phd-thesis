# A context variable, reset with a token after the inner scope.
from contextvars import ContextVar

pool: ContextVar[list] = ContextVar("pool")


def node(*n):
    pool.get().append(n)
    return len(pool.get()) - 1


def lit(n): return node("lit", n)
def add(l, r): return node("add", l, r)
def mul(l, r): return node("mul", l, r)


def ev(e):
    match pool.get()[e]:
        case ("lit", n): return n
        case ("add", l, r): return ev(l) + ev(r)
        case ("mul", l, r): return ev(l) * ev(r)


pool.set([])
e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
print(ev(e))
token = pool.set([])
print(ev(add(lit(4), lit(4))))
pool.reset(token)
print(ev(e))
