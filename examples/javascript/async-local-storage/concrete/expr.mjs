// AsyncLocalStorage: `run` binds the pool for a callback and everything it calls.
import { AsyncLocalStorage } from "node:async_hooks";

class ExprPool {
  #exprs = [];
  add(expr) {
    return this.#exprs.push(expr) - 1;
  }
  get(expr) {
    return this.#exprs[expr];
  }
}

const pool = new AsyncLocalStorage();

// An expression is { op, lhs, rhs } or { num }; an ExprRef is its index.
const interp = (expr) => {
  const e = pool.getStore().get(expr);
  if (!("op" in e)) return e.num;
  const l = interp(e.lhs);
  const r = interp(e.rhs);
  switch (e.op) {
    case "add": return l + r;
    case "sub": return l - r;
    case "mul": return l * r;
    case "div": return r === 0 ? 0 : Math.trunc(l / r);
  }
};

const num = (n) => pool.getStore().add({ num: n });
const bin = (op, lhs, rhs) => pool.getStore().add({ op, lhs, rhs });

pool.run(new ExprPool(), () => {
  const e = bin("div", bin("mul", bin("sub", num(7), num(10)), num(7)), num(2));
  console.log(interp(e));
  pool.run(new ExprPool(), () =>
    console.log(interp(bin("div", bin("add", num(4), num(4)), bin("sub", num(4), num(4))))));
  console.log(interp(e));
});
