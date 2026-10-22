// AsyncLocalStorage: `run` binds the pool for a callback and everything it calls.
import { AsyncLocalStorage } from "node:async_hooks";

const pool = new AsyncLocalStorage();

const push = (node) => pool.getStore().push(node) - 1;
const lit = (n) => push({ op: "lit", n });
const add = (l, r) => push({ op: "add", l, r });
const mul = (l, r) => push({ op: "mul", l, r });

const evaluate = (e) => {
  const node = pool.getStore()[e];
  switch (node.op) {
    case "lit": return node.n;
    case "add": return evaluate(node.l) + evaluate(node.r);
    case "mul": return evaluate(node.l) * evaluate(node.r);
  }
};

pool.run([], () => {
  const e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
  console.log(evaluate(e));
  pool.run([], () => console.log(evaluate(add(lit(4), lit(4)))));
  console.log(evaluate(e));
});
