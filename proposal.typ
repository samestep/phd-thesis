#import "snippet.typ": diff, listings, snippet

#set raw(syntaxes: "syntaxes/moss.sublime-syntax")

#show: listings

#show quote.where(block: true): it => block(
  width: 100%,
  stroke: (left: 2pt + luma(75%)),
  outset: (left: -0.4em, y: 0.5em),
  it,
)

#let citet(key) = cite(key, form: "prose")

#align(center)[
  = Ambient Polymorphism

  Sam Estep
]

= Abstract

...

= Introduction

PostgreSQL 11.22 (#cite(<postgresql2023>, form: "year")) returns zero for the following query @numacc4:

#snippet("postgres/NumAcc4.sql")

Why? Up until version 12, Postgres computed standard deviation by first computing $a = sum x$ and $b = sum x^2$ ...

#snippet("vendor/postgres/src/backend/utils/adt/float.c", from: 2727, to: 2731)

... and then computing $N b - a^2$:

#snippet("vendor/postgres/src/backend/utils/adt/float.c", from: 2942, to: 2947)

This catastrophic cancellation is

#quote(block: true, attribution: <simon1988>)[
  the notorious desk top calculator algorithm, also known as the one-pass algorithm.
]

#quote(block: true, attribution: <kahan2006>)[
  Higher precision will very often estimate a "correct" path well enough. To this end, imagine a debugger that can transform a given subprogram p, whose literal constants and variables x, y, z,~... have been declared by the programmer to have precisions thought adequate at the time, into an analogous subprogram P whose corresponding literal constants and variables X, Y, Z,~... are declared by the debugger to have greater precisions, preferably about twice as great. Then the debugger can execute both programs p and P simultaneously (actually interleaved) with the same input (or copies of it if the subprogram will change it) and compare their progress to see where one of the variables x, y, z,~... first departs excessively from its analog X, Y, Z,~...~.
]

#bibliography("refs.yml", style: "chicago-author-date")
