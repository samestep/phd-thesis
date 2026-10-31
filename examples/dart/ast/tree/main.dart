// The tree Sampson starts from: each node holds references to its children,
// so nothing needs a pool, and the GC reclaims nodes nobody points to.
enum BinOp { add, sub, mul, div }

sealed class Expr {}

class Binary extends Expr {
  final BinOp op;
  final Expr lhs, rhs;
  Binary(this.op, this.lhs, this.rhs);
}

class Literal extends Expr {
  final int num;
  Literal(this.num);
}

int interp(Expr expr) => switch (expr) {
      Binary(:var op, :var lhs, :var rhs) => switch ((op, interp(lhs), interp(rhs))) {
          (BinOp.add, var l, var r) => l + r,
          (BinOp.sub, var l, var r) => l - r,
          (BinOp.mul, var l, var r) => l * r,
          (BinOp.div, var l, var r) => r == 0 ? 0 : l ~/ r,
        },
      Literal(:var num) => num,
    };

Expr num(int n) => Literal(n);
Expr bin(BinOp op, Expr l, Expr r) => Binary(op, l, r);

void main() {
  var e = bin(BinOp.div, bin(BinOp.mul, bin(BinOp.sub, num(7), num(10)), num(7)), num(2));
  print(interp(e));
  {
    var f = bin(BinOp.div, bin(BinOp.add, num(4), num(4)), bin(BinOp.sub, num(4), num(4)));
    print(interp(f));
  }
  print(interp(e));
}
