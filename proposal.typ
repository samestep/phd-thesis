#import "snippet.typ": diff, listings, snippet

#set raw(syntaxes: "syntaxes/moss.sublime-syntax")

#show: listings

#let citet(key) = cite(key, form: "prose")

#align(center)[
  = Call-Tree Polymorphism

  Sam Estep
]

= Abstract

...

= Introduction

In any programming language, one must trade off readability and maintainability on the one hand, and performance on the other hand. One common source of this tension is the need to access objects related to a given one. #citet(<sampson2023>) illustrates this through an example interpreter of arithmetic expressions.

#snippet("examples/rust/ast/tree/tree.rs", from: "enum BinOp", through: "impl Expr")

Using `Box` is easy but leaves performance on the table. A more efficient allocation strategy is to store expressions in an _arena_ as a single allocation, rather than giving each its own allocation.

#diff(
  (path: "examples/rust/ast/tree/tree.rs", from: "enum Expr"),
  (path: "examples/rust/ast/explicit/concrete/flat.rs", from: "enum Expr", to: "struct ExprPool"),
)

But this comes at a cost. We can no longer just write `expr.interp()` on some `&Expr`. Now any operation that would previously have taken an `&Expr` needs to take an `ExprRef` instead... and _also_ an `ExprPool`, because the `ExprRef` doesn't have a "direct" way to access its data in the way that an `&Expr` does. So the natural pattern is to essentially treat `ExprPool` as a monad, and implement any `Expr`-related operation as a method on `ExprPool`.

#diff(
  (path: "examples/rust/ast/tree/tree.rs", from: "impl Expr", to: "impl Expr"),
  (path: "examples/rust/ast/explicit/concrete/flat.rs", from: "impl ExprPool", to: "impl ExprPool"),
)

#diff(
  (path: "examples/rust/ast/tree/tree.rs", from: "fn interp(", to: "match self"),
  (path: "examples/rust/ast/explicit/concrete/flat.rs", from: "fn interp(", to: "match self"),
)

#diff(
  (path: "examples/rust/ast/tree/tree.rs", from: "let lhs", to: "let rhs"),
  (path: "examples/rust/ast/explicit/concrete/flat.rs", from: "let lhs", to: "let rhs"),
)

= Completed work

== Theory

(syntax figure)

(static semantics figure)

(dynamic semantics figure)

== Implementation

We have implemented a compiler from Moss to WebAssembly (TODO citation) (Wasm), written in Python. This implementation supports the full language described in the previous section, plus the following additional language features:

- TODO

We have also implemented a self-hosting compiler from Moss to Wasm, which can be bootstrapped from the Python implementation:

- The Python compiler is Tier 0.
- Tier 0 can be run on the Moss compiler source code to produce the Tier 1 compiler.
- The Tier 1 compiler can be run on the Moss compiler source code to produce the Tier 2 compiler.
- The Tier 2 compiler can be run on the Moss compiler source code to produce the Tier 3 compiler.

The Wasm binaries for the Tier 2 and Tier 3 compilers are bytewise identical.

= Proposed work

== Performance experiments

= Related work

Lisp

Koka

Zig

#bibliography("refs.yml", style: "chicago-author-date")
