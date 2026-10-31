// A generic interface: Ast<R> leaves the index type open, but an
// AsyncLocalStorage's type is fixed where it's declared, so the store comes
// back through an unchecked `as`: R is whatever each caller declares it to be
// (`const e: Idx = ...`).
import { AsyncLocalStorage } from "node:async_hooks";

type BinOp = "add" | "sub" | "mul" | "div";

type Expr<R> = { op: BinOp; lhs: R; rhs: R } | { num: number };

interface Ast<R> {
  add(expr: Expr<R>): R;
  get(expr: R): Expr<R>;
}

const ast = new AsyncLocalStorage<Ast<unknown>>();
function store<R>() {
  return ast.getStore() as Ast<R>;
}

function interp<R>(expr: R): number {
  const e = store<R>().get(expr);
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

function num<R>(n: number) {
  return store<R>().add({ num: n });
}

function bin<R>(op: BinOp, lhs: R, rhs: R) {
  return store<R>().add({ op, lhs, rhs });
}

const OPS = ["add", "sub", "mul", "div"] as const; // 0 is a literal

// Representation 1: a node is an index into parallel lists.
type Idx = number & { readonly __brand: "Idx" };

class Columns implements Ast<Idx> {
  #ops: number[] = [];
  #lhs: number[] = [];
  #rhs: number[] = [];
  add(e: Expr<Idx>): Idx {
    const [op, l, r] = "op" in e ? [OPS.indexOf(e.op) + 1, e.lhs, e.rhs] : [0, e.num, 0];
    this.#lhs.push(l);
    this.#rhs.push(r);
    return (this.#ops.push(op) - 1) as Idx;
  }
  get(i: Idx): Expr<Idx> {
    const op = this.#ops[i];
    if (op === 0) return { num: this.#lhs[i] };
    return { op: OPS[op - 1], lhs: this.#lhs[i] as Idx, rhs: this.#rhs[i] as Idx };
  }
}

// Representation 2: a node is an index into one list of triples.
type Slot = number & { readonly __brand: "Slot" };

class Triples implements Ast<Slot> {
  #triples: number[] = [];
  add(e: Expr<Slot>): Slot {
    if ("op" in e) this.#triples.push(OPS.indexOf(e.op) + 1, e.lhs, e.rhs);
    else this.#triples.push(0, e.num, 0);
    return (this.#triples.length / 3 - 1) as Slot;
  }
  get(i: Slot): Expr<Slot> {
    const [op, l, r] = this.#triples.slice(3 * i, 3 * i + 3);
    return op === 0 ? { num: l } : { op: OPS[op - 1], lhs: l as Slot, rhs: r as Slot };
  }
}

ast.run(new Columns(), () => {
  const e: Idx = bin("div", bin("mul", bin("sub", num(7), num(10)), num(7)), num(2));
  console.log(interp(e));
  ast.run(new Triples(), () => {
    const f: Slot = bin("div", bin("add", num(4), num(4)), bin("sub", num(4), num(4)));
    console.log(interp(f));
  });
  console.log(interp(e));
});
