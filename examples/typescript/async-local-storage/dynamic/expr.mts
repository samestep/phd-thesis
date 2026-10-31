// A plain interface: the store holds any `Ast`, with no cast, because
// `ExprRef` is fixed once for every representation, so the types no longer
// tell one pool's references from another's.
import { AsyncLocalStorage } from "node:async_hooks";

type BinOp = "add" | "sub" | "mul" | "div";

type ExprRef = number;

type Expr = { op: BinOp; lhs: ExprRef; rhs: ExprRef } | { num: number };

interface Ast {
  add(expr: Expr): ExprRef;
  get(expr: ExprRef): Expr;
}

const ast = new AsyncLocalStorage<Ast>();

function interp(expr: ExprRef): number {
  const e = ast.getStore()!.get(expr);
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
  return ast.getStore()!.add({ num: n });
}

function bin(op: BinOp, lhs: ExprRef, rhs: ExprRef) {
  return ast.getStore()!.add({ op, lhs, rhs });
}

const OPS = ["add", "sub", "mul", "div"] as const; // 0 is a literal

// Representation 1: a node is an index into parallel lists.
class Columns implements Ast {
  #ops: number[] = [];
  #lhs: number[] = [];
  #rhs: number[] = [];
  add(e: Expr): ExprRef {
    const [op, l, r] = "op" in e ? [OPS.indexOf(e.op) + 1, e.lhs, e.rhs] : [0, e.num, 0];
    this.#lhs.push(l);
    this.#rhs.push(r);
    return this.#ops.push(op) - 1;
  }
  get(i: ExprRef): Expr {
    const op = this.#ops[i];
    if (op === 0) return { num: this.#lhs[i] };
    return { op: OPS[op - 1], lhs: this.#lhs[i], rhs: this.#rhs[i] };
  }
}

// Representation 2: a node is an index into one list of triples.
class Triples implements Ast {
  #triples: number[] = [];
  add(e: Expr): ExprRef {
    if ("op" in e) this.#triples.push(OPS.indexOf(e.op) + 1, e.lhs, e.rhs);
    else this.#triples.push(0, e.num, 0);
    return this.#triples.length / 3 - 1;
  }
  get(i: ExprRef): Expr {
    const [op, l, r] = this.#triples.slice(3 * i, 3 * i + 3);
    return op === 0 ? { num: l } : { op: OPS[op - 1], lhs: l, rhs: r };
  }
}

ast.run(new Columns(), () => {
  const e = bin("div", bin("mul", bin("sub", num(7), num(10)), num(7)), num(2));
  console.log(interp(e));
  ast.run(new Triples(), () => {
    const f = bin("div", bin("add", num(4), num(4)), bin("sub", num(4), num(4)));
    console.log(interp(f));
  });
  console.log(interp(e));
});
