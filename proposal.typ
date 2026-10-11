= Introduction

In any programming language, one must trade off readability and maintainability on the one hand, and performance on the other hand. One common source of this tension is the need to access objects related to a given one.

(code example)

The most _convenient_ way to write this code would be if `foo` had a field called `bar`. But this causes problems if there are a _million_ `Foo`s.

= Prior work

Lisp

Koka

Zig

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
