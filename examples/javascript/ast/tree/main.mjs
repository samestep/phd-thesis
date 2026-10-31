// The tree Sampson starts from: each node holds references to its children,
// so nothing needs a pool, but every node is its own heap object.

// An expression is { op, lhs, rhs } or { num }.
const interp = (e) => {
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

const num = (n) => ({ num: n });
const bin = (op, lhs, rhs) => ({ op, lhs, rhs });

const e = bin("div", bin("mul", bin("sub", num(7), num(10)), num(7)), num(2));
console.log(interp(e));
{
  const f = bin("div", bin("add", num(4), num(4)), bin("sub", num(4), num(4)));
  console.log(interp(f));
}
console.log(interp(e));
