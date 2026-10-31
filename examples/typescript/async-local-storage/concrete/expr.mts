// AsyncLocalStorage: `run` binds the pool for a callback and everything it calls.
import { AsyncLocalStorage } from "node:async_hooks";

type BinOp = "add" | "sub" | "mul" | "div";

type ExprRef = number;

type Expr = { op: BinOp; lhs: ExprRef; rhs: ExprRef } | { num: number };

class ExprPool {
  #exprs: Expr[] = [];
  add(expr: Expr): ExprRef {
    return this.#exprs.push(expr) - 1;
  }
  get(expr: ExprRef): Expr {
    return this.#exprs[expr];
  }
}

const pool = new AsyncLocalStorage<ExprPool>();

function interp(expr: ExprRef): number {
  const e = pool.getStore()!.get(expr);
  if (!("op" in e)) return e.num;
  const l = interp(e.lhs);
  const r = interp(e.rhs);
  switch (e.op) {
    case "add": return l + r;
    case "sub": return l - r;
    case "mul": return l * r;
    case "div": return r === 0 ? 0 : Math.trunc(l / r);
  }
}

function num(n: number) {
  return pool.getStore()!.add({ num: n });
}

function bin(op: BinOp, lhs: ExprRef, rhs: ExprRef) {
  return pool.getStore()!.add({ op, lhs, rhs });
}

pool.run(new ExprPool(), () => {
  const e = bin("div", bin("mul", bin("sub", num(7), num(10)), num(7)), num(2));
  console.log(interp(e));
  pool.run(new ExprPool(), () => {
    const f = bin("div", bin("add", num(4), num(4)), bin("sub", num(4), num(4)));
    console.log(interp(f));
  });
  console.log(interp(e));
});
