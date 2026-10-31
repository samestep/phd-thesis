// A generic interface: Ast<R> leaves the index type open, but zone values are
// untyped, so the pool comes back through a cast, and R is whatever each
// caller declares it to be (`Idx e = ...`). The cast is checked at run time,
// but there `Idx` and `Slot` are both just `int`.
import 'dart:async';

enum BinOp { add, sub, mul, div }

sealed class Expr<R> {}

class Binary<R> extends Expr<R> {
  final BinOp op;
  final R lhs, rhs;
  Binary(this.op, this.lhs, this.rhs);
}

class Literal<R> extends Expr<R> {
  final int num;
  Literal(this.num);
}

abstract interface class Ast<R> {
  R add(Expr<R> expr);
  Expr<R> get(R expr);
}

Ast<R> ast<R>() => Zone.current[#ast] as Ast<R>;

int interp<R>(R expr) => switch (ast<R>().get(expr)) {
      Binary(:var op, :var lhs, :var rhs) => switch ((op, interp(lhs), interp(rhs))) {
          (BinOp.add, var l, var r) => l + r,
          (BinOp.sub, var l, var r) => l - r,
          (BinOp.mul, var l, var r) => l * r,
          (BinOp.div, var l, var r) => r == 0 ? 0 : l ~/ r,
        },
      Literal(:var num) => num,
    };

R num<R>(int n) => ast<R>().add(Literal(n));
R bin<R>(BinOp op, R l, R r) => ast<R>().add(Binary(op, l, r));

// Operators are stored as codes: 0 is a literal, and BinOp n is n + 1.
Expr<R> node<R>(int op, int lhs, int rhs, R Function(int) ref) =>
    op == 0 ? Literal(lhs) : Binary(BinOp.values[op - 1], ref(lhs), ref(rhs));

// Representation 1: a node is an index into parallel lists.
extension type Idx(int index) {}

class Columns implements Ast<Idx> {
  final _ops = <int>[], _lhs = <int>[], _rhs = <int>[];

  @override
  Idx add(Expr<Idx> expr) {
    var (op, l, r) = switch (expr) {
      Binary(:var op, :var lhs, :var rhs) => (op.index + 1, lhs.index, rhs.index),
      Literal(:var num) => (0, num, 0),
    };
    _ops.add(op);
    _lhs.add(l);
    _rhs.add(r);
    return Idx(_ops.length - 1);
  }

  @override
  Expr<Idx> get(Idx expr) => node(_ops[expr.index], _lhs[expr.index], _rhs[expr.index], Idx.new);
}

// Representation 2: a node is an index into one list of triples.
extension type Slot(int index) {}

class Triples implements Ast<Slot> {
  final _triples = <int>[];

  @override
  Slot add(Expr<Slot> expr) {
    _triples.addAll(switch (expr) {
      Binary(:var op, :var lhs, :var rhs) => [op.index + 1, lhs.index, rhs.index],
      Literal(:var num) => [0, num, 0],
    });
    return Slot(_triples.length ~/ 3 - 1);
  }

  @override
  Expr<Slot> get(Slot expr) {
    var i = 3 * expr.index;
    return node(_triples[i], _triples[i + 1], _triples[i + 2], Slot.new);
  }
}

void main() {
  runZoned(() {
    Idx e = bin(BinOp.div, bin(BinOp.mul, bin(BinOp.sub, num(7), num(10)), num(7)), num(2));
    print(interp(e));
    runZoned(() {
      Slot f = bin(BinOp.div, bin(BinOp.add, num(4), num(4)), bin(BinOp.sub, num(4), num(4)));
      print(interp(f));
    }, zoneValues: {#ast: Triples()});
    print(interp(e));
  }, zoneValues: {#ast: Columns()});
}
