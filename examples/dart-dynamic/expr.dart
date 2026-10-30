// A plain interface: the zone holds any `Ast`, with `ExprRef` fixed once for
// every representation, so the types no longer tell one pool's references
// from another's.
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

abstract interface class Ast {
  ExprRef add(Expr expr);
  Expr get(ExprRef expr);
}

Ast get ast => Zone.current[#ast] as Ast;

int interp(ExprRef expr) => switch (ast.get(expr)) {
      Binary(:var op, :var lhs, :var rhs) => switch ((op, interp(lhs), interp(rhs))) {
          (BinOp.add, var l, var r) => l + r,
          (BinOp.sub, var l, var r) => l - r,
          (BinOp.mul, var l, var r) => l * r,
          (BinOp.div, var l, var r) => r == 0 ? 0 : l ~/ r,
        },
      Literal(:var num) => num,
    };

ExprRef num(int n) => ast.add(Literal(n));
ExprRef bin(BinOp op, ExprRef l, ExprRef r) => ast.add(Binary(op, l, r));

// Operators are stored as codes: 0 is a literal, and BinOp n is n + 1.
Expr node(int op, int lhs, int rhs) =>
    op == 0 ? Literal(lhs) : Binary(BinOp.values[op - 1], ExprRef(lhs), ExprRef(rhs));

// Representation 1: a node is an index into parallel lists.
class Columns implements Ast {
  final _ops = <int>[], _lhs = <int>[], _rhs = <int>[];

  @override
  ExprRef add(Expr expr) {
    var (op, l, r) = switch (expr) {
      Binary(:var op, :var lhs, :var rhs) => (op.index + 1, lhs.index, rhs.index),
      Literal(:var num) => (0, num, 0),
    };
    _ops.add(op);
    _lhs.add(l);
    _rhs.add(r);
    return ExprRef(_ops.length - 1);
  }

  @override
  Expr get(ExprRef expr) => node(_ops[expr.index], _lhs[expr.index], _rhs[expr.index]);
}

// Representation 2: a node is an index into one list of triples.
class Triples implements Ast {
  final _triples = <int>[];

  @override
  ExprRef add(Expr expr) {
    _triples.addAll(switch (expr) {
      Binary(:var op, :var lhs, :var rhs) => [op.index + 1, lhs.index, rhs.index],
      Literal(:var num) => [0, num, 0],
    });
    return ExprRef(_triples.length ~/ 3 - 1);
  }

  @override
  Expr get(ExprRef expr) {
    var i = 3 * expr.index;
    return node(_triples[i], _triples[i + 1], _triples[i + 2]);
  }
}

void main() {
  runZoned(() {
    var e = bin(BinOp.div, bin(BinOp.mul, bin(BinOp.sub, num(7), num(10)), num(7)), num(2));
    print(interp(e));
    runZoned(
      () => print(interp(bin(BinOp.div, bin(BinOp.add, num(4), num(4)), bin(BinOp.sub, num(4), num(4))))),
      zoneValues: {#ast: Triples()},
    );
    print(interp(e));
  }, zoneValues: {#ast: Columns()});
}
