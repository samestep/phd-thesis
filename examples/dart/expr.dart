// Zone values: `runZoned` binds the pool for everything run inside it.
import 'dart:async';

sealed class Node {}

class Lit extends Node {
  final int n;
  Lit(this.n);
}

class Add extends Node {
  final int l, r;
  Add(this.l, this.r);
}

class Mul extends Node {
  final int l, r;
  Mul(this.l, this.r);
}

List<Node> get pool => Zone.current[#pool] as List<Node>;

int push(Node node) {
  pool.add(node);
  return pool.length - 1;
}

int lit(int n) => push(Lit(n));
int add(int l, int r) => push(Add(l, r));
int mul(int l, int r) => push(Mul(l, r));

int eval(int e) => switch (pool[e]) {
      Lit(:var n) => n,
      Add(:var l, :var r) => eval(l) + eval(r),
      Mul(:var l, :var r) => eval(l) * eval(r),
    };

void main() {
  runZoned(() {
    var e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
    print(eval(e));
    runZoned(() => print(eval(add(lit(4), lit(4)))), zoneValues: {#pool: <Node>[]});
    print(eval(e));
  }, zoneValues: {#pool: <Node>[]});
}
