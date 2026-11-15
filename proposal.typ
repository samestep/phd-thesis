#import "lib.typ": (
  bnf, choice, citet, diff, many, opt, seq, snippet, style, title-page,
)

#show: style

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

This document proposes a novel programming language design which we call _ambient polymorphism_, with the following thesis:

#quote(block: true)[
  *The cost of writing programs that are flexible by default can be greatly reduced by decoupling polymorphism from dataflow.*
]

#figure(
  placement: top,
  snippet("examples/moss/NumAcc4.moss"),
  caption: [The NumAcc4 failure example in Moss.],
) <stddev-moss>

@stddev-moss shows the numerically unstable standard deviation algorithm translated into _Moss_, an experimental programming language that reifies ambient polymorphism.

#figure(
  placement: top,
  kind: raw,
  diff(
    (path: "examples/moss/NumAcc4.moss"),
    (path: "examples/moss/NumAcc4Precise.moss"),
    context-lines: 2,
  ),
  caption: [Switching from double precision to double-double precision.],
) <stddev-precise>

Even though this program is statically typed and does not explicitly define a generic type parameter for floating-point precision, it nonetheless benefits from Moss's ambient polymorphism. @stddev-precise shows how only a couple lines of code are required to switch from double precision to double-double precision. This modified program prints `0.1`.

@completed describes the theory, language design and current implementation. @proposed sketches out a plan for evaluation. @related situates this work within the body of relevant research literature.

= Completed work <completed>

== Theory

#figure(
  placement: top,
  kind: image,
  text(10pt, bnf(
    ([File], $F$, ([#many[$m$] #many[$d$]],)),
    (
      [Import],
      $m$,
      ([`import` _quoted_ #opt[`as` $x$] #opt[`use *` $|$ `use` #seq[$u$]]],),
    ),
    ([Use], $u$, ($x$, [$x$ `as` $x$], [`.`$x$], [`.`$x$ `as .`$x$])),
    ([Path], $p$, ($x$, [$p$`::`$x$])),
    ([Head], $h$, ($p$, [$p$`.`$x$])),
    (
      [Specification],
      $s$,
      ([$p$#opt[`[`#seq[$p$` = `$r$]`]`]], $q$),
    ),
    (
      [Method specification],
      $q$,
      ([$p$`.`$x$#opt[`[`#seq[$p$` = `$r$]`]`]],),
    ),
    ([Type reference], $r$, ([$p$#opt[`[`#seq[$p$` = `$r$]`]`]],)),
    ([Assume item], $a$, ($h$, [$r$` = `$r$])),
    ([Context item], $c$, ($s$, [$r$` = `$r$])),
    (
      [Type],
      $tau$,
      (
        $r$,
        `This`,
        `()`,
        `|`,
        [`{`#seq[$x$`: `$tau$]`}`],
        [$tau_1$ `|` $dots$ `|` $tau_n$ $(n >= 2)$],
      ),
    ),
    (
      [Declaration],
      $d$,
      ([`assume` #seq[$a$]` {`#many[$d$]`}`], [`context` $x$` = `#seq[$c$]]),
      (
        [`type` $x$],
        [`type` $x$` = `$tau$],
        [`val` $x$`: `$tau$ #opt[`= `$e$]],
      ),
      ([`tag` $x$], [`tag` $x$#opt[`[`#seq[$x$]`]`]`(`$tau$`)`]),
      ([`fn` $f$`(`#seq[$x$`: `$tau$]`): `$tau$ #opt[$b$]],),
      ([`functor` $x$#opt[`[`#seq[$x$]`]`]`: `#seq[$s$]` -> `#seq[$s$]],),
      ([`functor` $x$`: `#seq[$s$]` -> `#seq[$s$]` {`#many[$w$]`}`],),
    ),
    ([Function name], $f$, ($x$, [$x$`.`$x$], [`.`$x$])),
    ([Binding form], $j$, ([$x$#opt[`: `$tau$]],)),
    ([Block], $b$, ([`{`#many[$i$] #opt[$e$]`}`],)),
    (
      [Statement],
      $i$,
      ([`let` $j$` = `$e$], [`var` $j$` = `$e$], [$x$` = `$e$], $w$),
      ([`while` $e$ $b$], [`loop` $b$], $e$),
    ),
    ([Bind statement], $w$, ([`bind` $beta$],)),
    (
      [Bind item],
      $beta$,
      ($p$, [$p$` = `$r$], [$p$` = `$e$], [$p$` = `$p'$], [$q$` = `$h$]),
    ),
    (
      [Expression],
      $e$,
      ($p$, `()`, `this`, $b$, [`{`#seq[$x$` = `$e$]`}`]),
      ([$p$`(`#seq[$e$]`)`], $r ⟨e⟩$, [$e$`.`$x$], [$e$`.`$p$`(`#seq[$e$]`)`]),
      ([`match` $e$` {`#seq[$pi$` => `$e$]`}`], [`return` $e$], `break`),
    ),
    (
      [Pattern],
      $pi$,
      (`_`, $p$, [$p$`(`$x$`)`], [$p$`{`#seq[$x$` = `#choice($x$, `_`)]`}`]),
    ),
  )),
  caption: [Core Moss abstract syntax (full syntax can be found in @syntax-full). $x$ ranges over names, including the fresh names introduced by desugaring, and _quoted_ is a quoted path. $(X)^?$ marks an optional part, $X^*$ denotes repetition, and $overline(X)$ is a sequence. $r ⟨e⟩$ constructs a tag with payload $e$.],
) <syntax>

@syntax gives the abstract syntax.

= Proposed work <proposed>

= Related work <related>

#bibliography("refs.yml", style: "chicago-author-date")

#counter(heading).update(0)
#set heading(numbering: "A.", supplement: [Appendix])

= Full syntax

#figure(
  kind: image,
  text(10pt, bnf(
    ([File], $F$, ([#many[$m$] #many[$d$]],)),
    (
      [Import],
      $m$,
      ([`import` _quoted_ #opt[`as` $x$] #opt[`use *` $|$ `use` #seq[$u$]]],),
    ),
    ([Use], $u$, ($x$, [$x$ `as` $x$], [`.`$x$], [`.`$x$ `as .`$x$])),
    ([Path], $p$, ($x$, [$p$`::`$x$])),
    ([Head], $h$, ($p$, [$p$`.`$x$])),
    (
      [Specification],
      $s$,
      ([$p$#opt[`[`#seq[$p$` = `$r$]`]`]], $q$),
    ),
    (
      [Method specification],
      $q$,
      ([$p$`.`$x$#opt[`[`#seq[$p$` = `$r$]`]`]],),
    ),
    ([Type reference], $r$, ([$p$#opt[`[`#seq[$p$` = `$r$]`]`]],)),
    ([Assume item], $a$, ($h$, [$r$` = `$r$])),
    ([Context item], $c$, ($s$, [$r$` = `$r$])),
    (
      [Type],
      $tau$,
      (
        $r$,
        `This`,
        `()`,
        `|`,
        [`{`#seq[$x$`: `$tau$]`}`],
        [$tau_1$ `|` $dots$ `|` $tau_n$ $(n >= 2)$],
      ),
      ([`(`#seq[$tau$]`)`],),
    ),
    (
      [Declaration],
      $d$,
      ([`assume` #seq[$a$]` {`#many[$d$]`}`], [`context` $x$` = `#seq[$c$]]),
      (
        [`type` $x$],
        [`type` $x$` = `$tau$],
        [`val` $x$`: `$tau$ #opt[`= `$e$]],
      ),
      ([`tag` $x$], [`tag` $x$#opt[`[`#seq[$x$]`]`]`(`#seq[$tau$]`)`]),
      ([`tag` $x$#opt[`[`#seq[$x$]`]`]`{`#seq[$x$`: `$tau$]`}`],),
      ([`fn` $f$`(`#seq[$j$]`)`#opt[`: `$tau$] #opt[$b$]],),
      ([`functor` $x$#opt[`[`#seq[$x$]`]`]`: `#seq[$s$]` -> `#seq[$s$]],),
      ([`functor` $x$`: `#seq[$s$]` -> `#seq[$s$]` {`#many[$w$]`}`],),
    ),
    ([Function name], $f$, ($x$, [$x$`.`$x$], [`.`$x$])),
    (
      [Binding form],
      $j$,
      (
        [$x$#opt[`: `$tau$]],
        [`(`#seq[$j$]`)`#opt[`: `$tau$]],
        [`{`#seq[$x$` = `$j$]`}`#opt[`: `$tau$]],
      ),
      (
        [$p$`(`#seq[$j$]`)`#opt[`: `$tau$]],
        [$p$`{`#seq[$x$` = `$j$]`}`#opt[`: `$tau$]],
      ),
    ),
    ([Block], $b$, ([`{`#many[$i$] #opt[$e$]`}`],)),
    (
      [Statement],
      $i$,
      ([`let` $j$` = `$e$], [`var` $j$` = `$e$], [$x$ $alpha$ $e$], $w$),
      ([`while` $e$ $b$], [`loop` $b$], [`for` $x$ `in` $e$ $b$], $e$),
    ),
    (
      [Assignment],
      $alpha$,
      (`=`, `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`),
    ),
    ([Bind statement], $w$, ([`bind` #seq[$beta$]],)),
    (
      [Bind item],
      $beta$,
      ($p$, [$p$` = `$r$], [$p$` = `$e$], [$p$` = `$p'$], [$q$` = `$h$]),
      ([#choice($p$, $q$)` = (`#seq[$j$]`)`#opt[`: `$tau$]` => `$e$],),
    ),
    (
      [Expression],
      $e$,
      ($p$, `()`, `this`, $b$, [_int_], [_dec_], [_str_], [`(`#seq[$e$]`)`]),
      (
        [#opt[$r$]`{`#seq[$x$` = `$e$]`}`],
        [$e$`.`$x$],
        [$e$`.`$p$`(`#seq[$e$]`)`],
      ),
      ([$p$#opt[`[`#seq[$beta$]`]`]`(`#seq[$e$]`)`],),
      (
        [`if` $e$ $b$ #opt[`else` $e$]],
        [`match` $e$` {`#seq[$pi$` => `$e$]`}`],
      ),
      ([`return` #opt[$e$]], `break`, [$o_1 e$], [$e o_2 e$]),
    ),
    ([Unary operator], $o_1$, (`-`, `!`)),
    (
      [Binary operator],
      $o_2$,
      (
        `*`,
        `/`,
        `%`,
        `+`,
        `-`,
        `<<`,
        `>>`,
        `<`,
        `<=`,
        `>`,
        `>=`,
        `==`,
        `!=`,
        `&`,
        `^`,
        `|`,
      ),
    ),
    (
      [Pattern],
      $pi$,
      (`_`, $p$, [$p$`(`#seq[$y$]`)`], [$p$`{`#seq[$x$` = `$y$]`}`]),
    ),
    ([Payload pattern], $y$, ($x$, `_`)),
  )),
  caption: [Full syntax, expanded from @syntax. $x$ ranges over names, $(X)^?$ marks an optional part, and $X^*$ denotes repetition. $overline(X)$ is a possibly empty sequence. Parenthesized sequences of types and expressions denote nonempty tuples.],
) <syntax-full>
