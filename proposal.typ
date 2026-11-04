#import "lib.typ": bnf, diff, listings, opt, seq, snippet, title-page

#set raw(syntaxes: "syntaxes/moss.sublime-syntax")

#show: listings

#show quote.where(block: true): it => block(
  width: 100%,
  stroke: (left: 2pt + luma(75%)),
  outset: (left: -0.4em, y: 0.5em),
  it,
)

#let citet(key) = cite(key, form: "prose")

#title-page(
  title: [Ambient Polymorphism],
  author: [Sam Estep],
  committee: (([Joshua Sunshine, Chair], [Carnegie Mellon University]),),
)

== Abstract

...

#set heading(numbering: "1.")

= Introduction

PostgreSQL 11.22 (#cite(<postgresql2023>, form: "year")) returns zero for the following query @numacc4:

#snippet("postgres/NumAcc4.sql")

Why? Up until version 12, Postgres computed standard deviation by first computing $a = sum x$ and $b = sum x^2$ ...

#snippet("vendor/postgres/src/backend/utils/adt/float.c", from: 2727, to: 2731)

... and then computing $N b - a^2$:

#snippet("vendor/postgres/src/backend/utils/adt/float.c", from: 2942, to: 2947)

This bug was eventually discovered by a third-party domain expert @schubert2018bug who was searching for instances of this exact formula. This dependence on deep expertise is unfortunate, because in theory it's very simple to find these sorts of bugs; simply observe what happens when the program is run with higher precision:

#quote(block: true, attribution: <kahan2006>)[
  Higher precision will very often estimate a "correct" path well enough. To this end, imagine a debugger that can transform a given subprogram p, whose literal constants and variables x, y, z,~... have been declared by the programmer to have precisions thought adequate at the time, into an analogous subprogram P whose corresponding literal constants and variables X, Y, Z,~... are declared by the debugger to have greater precisions, preferably about twice as great. Then the debugger can execute both programs p and P simultaneously (actually interleaved) with the same input (or copies of it if the subprogram will change it) and compare their progress to see where one of the variables x, y, z,~... first departs excessively from its analog X, Y, Z,~...~.
]

But the reason we have to _imagine_ such a tool is because we would have to go out of our way to create it. The programming languages we use do not make it easy to perform such transformations unless one plan ahead and writes less straightforward code in the hope that it will pay off later. Of course, often it doesn't pay off. So often the smart thing to do is to avoid paying the cost of extra complexity by just writing the straightforward code in the first place.

This document proposes a novel programming language design which we call _ambient polymorphism_, with the thesis that *the cost of writing flexible programs can be drastically reduced by decoupling polymorphism from dataflow*. @completed describes the language design and current implementation. @proposed sketches out a plan for evaluation. @related situates this work within the body of relevant research literature.

= Completed work <completed>

#figure(
  placement: auto,
  snippet("examples/moss/shadow/context/stddev.moss", from: "fn stddev("),
  caption: [The numerically unstable one-pass algorithm for computing standard deviation, implemented in Moss.],
) <stddev-moss>

#figure(
  placement: auto,
  kind: image,
  bnf(
    ([File], $F$, ([#seq[$m$] #seq[$d$]],)),
    (
      [Import],
      $m$,
      ([`import` _str_ #opt[`as` $x$] #opt[`use *` $|$ `use` #seq[$u$]]`;`],),
    ),
    ([Use], $u$, ($x$, [$x$ `as` $x$], [`.`$x$], [`.`$x$ `as .`$x$])),
    ([Path], $p$, ($x$, [$p$`::`$x$])),
    ([Head], $h$, ($p$, [$p$`.`$x$], [`.`$x$])),
    ([Spec], $s$, ($h$, [$h$`[`#seq[$p$` = `$s$]`]`])),
    ([Reference], $r$, ($p$, [$p$`[`#seq[$p$` = `$s$]`]`])),
    (
      [Type],
      $tau$,
      (
        $r$,
        `This`,
        `()`,
        [`(`$tau$`)`],
        [`{`#seq[$x$`: `$tau$]`}`],
        [$tau$` | `$tau$],
        `|`,
      ),
    ),
    (
      [Declaration],
      $d$,
      ([`assume` #seq[$h$]` {`#seq[$d$]`}`],),
      (
        [`type` $x$`;`],
        [`type` $x$` = `$tau$`;`],
        [`val` $x$`: `$tau$ #opt[`= `$e$]`;`],
      ),
      (
        [`tag` $x$`;`],
        [`tag` $x$#opt[`[`#seq[$x$]`]`]`(`$tau$`);`],
        [`tag` $x$#opt[`[`#seq[$x$]`]`]`{`#seq[$x$`: `$tau$]`};`],
      ),
      (
        [`fn` $f$`(`#seq[$x$`: `$tau$]`)`#opt[`: `$tau$]`;`],
        [`fn` $f$`(`#seq[$x$`: `$tau$]`)`#opt[`: `$tau$] $b$],
      ),
      ([`context` $x$` = `#seq[$s$]`;`],),
      ([`functor` $x$#opt[`[`#seq[$x$]`]`]`: `#seq[$s$]` -> `#seq[$s$]`;`],),
      ([`functor` $x$`: `#seq[$s$]` -> `#seq[$s$]` {`#seq[$w$]`}`],),
    ),
    ([Function], $f$, ($x$, [$x$`.`$x$], [`.`$x$])),
    ([Block], $b$, ([`{`#seq[$i$] #opt[$e$]`}`],)),
    (
      [Statement],
      $i$,
      (
        [`let` $x$#opt[`: `$tau$]` = `$e$`;`],
        [`var` $x$#opt[`: `$tau$]` = `$e$`;`],
        [$x$` = `$e$`;`],
        $w$,
      ),
      (
        [`while` $e$ $b$],
        [`loop` $b$],
        [`for` $x$ `in` $e$ $b$],
        [$e$`;`],
        [$e$],
      ),
    ),
    ([Bind], $w$, ([`bind` #seq[$beta$]`;`],)),
    (
      [Binding],
      $beta$,
      (
        $s$,
        [$s$` = `$e$],
        [$s$` = (`#seq[$x$#opt[`: `$tau$]]`)`#opt[`: `$tau$]` => `$e$],
      ),
    ),
    (
      [Expression],
      $e$,
      ($c$, [`match` $e$` {`#seq[$a$]`}`], [`return` #opt[$e$]], `break`),
      (
        [$e$`.`$p$`(`#seq[$e$]`)`],
        [$e$`.`$x$],
        [$e$ $plus.o$ $e$],
        [$minus.o$$e$],
        [`(`$e$`)`],
        `()`,
        `this`,
        $b$,
      ),
      (
        [_int_],
        [_dec_],
        $r$,
        [$r$`(`#seq[$e$]`)`],
        [$r$`{`#seq[$x$ #opt[`= `$e$]]`}`],
      ),
    ),
    (
      [Binary],
      $plus.o$,
      (
        `*`,
        `/`,
        `%`,
        `+`,
        `-`,
        `==`,
        `!=`,
        `<`,
        `>`,
        `<=`,
        `>=`,
        `<<`,
        `>>`,
        `&`,
        `^`,
        `|`,
      ),
    ),
    ([Unary], $minus.o$, (`-`, `!`)),
    ([Conditional], $c$, ([`if` $e$ $b$ #opt[`else` $b$ $|$ `else` $c$]],)),
    ([Arm], $a$, ([$pi$` => `$e$`,`], [$pi$` => `$b$ #opt[`,`]])),
    (
      [Pattern],
      $pi$,
      (
        `_`,
        $p$,
        [$p$`(`$pi$`)`],
        [`{`#seq[$x$ #opt[`= `$pi$]]`}`],
        [$p$`{`#seq[$x$ #opt[`= `$pi$]]`}`],
      ),
    ),
  ),
  caption: [The grammar of Moss. Here $x$ ranges over names, and _str_, _int_ and _dec_ over string, integer and decimal literals; $(X)^?$ marks an optional $X$, and $overline(X)$ a possibly empty sequence of $X$, separated by commas (with an optional trailing comma) unless $X$ is an import, declaration, statement, bind or arm. A bare `|` is the uninhabited type. An expression statement may omit its `;` only if it ends in `}`.],
) <grammar>

== Language design

@stddev-moss shows a translation of the Postgres `stddev` code into Moss. This example shows the basics of Moss syntax, which is fairly unremarkable. @grammar gives its grammar.

= Proposed work <proposed>

= Related work <related>

#bibliography("refs.yml", style: "chicago-author-date")
