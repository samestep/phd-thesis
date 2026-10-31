// Zone values: `runZoned` binds the pool for everything run inside it.
import 'dart:async';

enum BinOp { add, sub, mul, div }

extension type ExprRef(int index) {}

sealed class Expr {}

class Binary extends Expr {
  final BinOp op;
  final ExprRef lhs, rhs;
  Binary(this.op, this.lhs, this.rhs);
}

class Literal extends Expr {
  final int num;
  Literal(this.num);
}

class ExprPool {
  final _exprs = <Expr>[];

  ExprRef add(Expr expr) {
    _exprs.add(expr);
    return ExprRef(_exprs.length - 1);
  }

  Expr get(ExprRef expr) => _exprs[expr.index];
}

ExprPool get pool => Zone.current[#pool] as ExprPool;

int interp(ExprRef expr) => switch (pool.get(expr)) {
      Binary(:var op, :var lhs, :var rhs) => switch ((op, interp(lhs), interp(rhs))) {
          (BinOp.add, var l, var r) => l + r,
          (BinOp.sub, var l, var r) => l - r,
          (BinOp.mul, var l, var r) => l * r,
          (BinOp.div, var l, var r) => r == 0 ? 0 : l ~/ r,
        },
      Literal(:var num) => num,
    };

ExprRef num(int n) => pool.add(Literal(n));
ExprRef bin(BinOp op, ExprRef l, ExprRef r) => pool.add(Binary(op, l, r));

void main() {
  runZoned(() {
    var e = bin(BinOp.div, bin(BinOp.mul, bin(BinOp.sub, num(7), num(10)), num(7)), num(2));
    print(interp(e));
    runZoned(
      () => print(interp(bin(BinOp.div, bin(BinOp.add, num(4), num(4)), bin(BinOp.sub, num(4), num(4))))),
      zoneValues: {#pool: ExprPool()},
    );
    print(interp(e));
  }, zoneValues: {#pool: ExprPool()});
}
