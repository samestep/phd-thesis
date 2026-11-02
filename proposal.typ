#import "snippet.typ": snippet

#set raw(syntaxes: "syntaxes/moss.sublime-syntax")

// Code blocks sit on a light panel, with line numbers right-aligned in a
// column as wide as the block's last one. Each line's body is boxed in
// the rest of the width, so a line too long for it wraps under itself
// rather than under the numbers.
#show raw.where(block: true): it => {
  show raw.line: line => context {
    let width = measure(str(line.count)).width
    box(width: width, align(right, text(fill: luma(60%), str(line.number))))
    h(1em)
    box(width: 1fr, line.body)
  }
  block(fill: luma(96%), inset: 8pt, radius: 3pt, width: 100%, it)
}

= Introduction

In any programming language, one must trade off readability and maintainability on the one hand, and performance on the other hand. One common source of this tension is the need to access objects related to a given one. @sampson2023

#snippet("examples/moss/interp/context/main.moss", region: "interp")

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

#bibliography("refs.yml")
