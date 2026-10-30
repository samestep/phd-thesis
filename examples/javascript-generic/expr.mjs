// Duck typing: the store holds any object with `add` and `get`, and its
// references can be anything at all.
import { AsyncLocalStorage } from "node:async_hooks";

const ast = new AsyncLocalStorage();

// An expression is { op, lhs, rhs } or { num }; an ExprRef is whatever the
// representation says it is.
const interp = (expr) => {
  const e = ast.getStore().get(expr);
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

const num = (n) => ast.getStore().add({ num: n });
const bin = (op, lhs, rhs) => ast.getStore().add({ op, lhs, rhs });

const OPS = [, "add", "sub", "mul", "div"]; // 0 is a literal

// Representation 1: a node is an index into parallel lists.
class Idx {
  constructor(i) { this.i = i; }
}

class Columns {
  #ops = [];
  #lhs = [];
  #rhs = [];
  add(e) {
    const [op, l, r] = "op" in e ? [OPS.indexOf(e.op), e.lhs.i, e.rhs.i] : [0, e.num, 0];
    this.#lhs.push(l);
    this.#rhs.push(r);
    return new Idx(this.#ops.push(op) - 1);
  }
  get({ i }) {
    const op = this.#ops[i];
    if (op === 0) return { num: this.#lhs[i] };
    return { op: OPS[op], lhs: new Idx(this.#lhs[i]), rhs: new Idx(this.#rhs[i]) };
  }
}

// Representation 2: a node is an index into one list of triples.
class Slot {
  constructor(i) { this.i = i; }
}

class Triples {
  #triples = [];
  add(e) {
    if ("op" in e) this.#triples.push(OPS.indexOf(e.op), e.lhs.i, e.rhs.i);
    else this.#triples.push(0, e.num, 0);
    return new Slot(this.#triples.length / 3 - 1);
  }
  get({ i }) {
    const [op, l, r] = this.#triples.slice(3 * i, 3 * i + 3);
    return op === 0 ? { num: l } : { op: OPS[op], lhs: new Slot(l), rhs: new Slot(r) };
  }
}

ast.run(new Columns(), () => {
  const e = bin("div", bin("mul", bin("sub", num(7), num(10)), num(7)), num(2));
  console.log(interp(e));
  ast.run(new Triples(), () =>
    console.log(interp(bin("div", bin("add", num(4), num(4)), bin("sub", num(4), num(4))))));
  console.log(interp(e));
});
