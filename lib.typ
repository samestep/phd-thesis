// The proposal's own library: `snippet`, `diff` and `listings` for code,
// `bnf` for grammars, `title-page`, `citet`, and `style` for the whole
// document.
//
// `snippet` shows code from `examples/`, which `nix flake check` runs, numbered as
// the lines are numbered in the file and labelled with the file's name.
//
// Without `from`, the whole file. With `from`, the one line containing
// that text, through the end of the item it starts: the first later line
// indented no deeper, included if it is at the same depth and closes a
// bracket (as `}` does) and excluded otherwise (as for an
// indentation-delimited language, or the end of an enclosing block),
// passing over a line that is only an opening brace at the same depth. With
// `through`, instead through the end of the item starting at the first
// later line containing that text; with `to`, through that line itself. With
// `comments: true`, also the comment lines directly above. A `from` with
// newlines in it matches consecutive lines, each containing its part, and
// the item starts at the last: so `"Datum\nfloat8_accum("` takes in the
// return type that PostgreSQL's C puts on the line above. Each pattern
// is plain text, and `from` must match exactly one line, so that a file
// changing under the document fails the build rather than silently
// showing something else. Any of `from`, `through` and `to` may instead
// be a line number, counted from 1 as the snippet numbers them: the line
// the pattern would have matched. A number can't fail that way, so use
// one only for a file that can't change under the document, such as one
// under `vendor/` that a check keeps the same as upstream. The result is dedented, and the language for
// highlighting defaults to the file's extension.
//
// A file is labelled by its name alone, so no two files the document
// shows may share one.

// The line number of a snippet's first line, and its label, for the
// `listings` show rule below; a code block not made by `snippet` is
// numbered from 1, unlabelled.
#let first-line = state("snippet-first-line", 1)
#let file-label = state("snippet-label", none)
// Each name shown so far, with the path it was shown for.
#let shown = state("snippet-shown", (:))

#let comment-prefixes = ("//", "#", "--", ";", "/*", "*")

#let indent-of(line) = line.len() - line.trim(at: start).len()

// The last line of the item starting at line `i`.
#let item-end(lines, i) = {
  let depth = indent-of(lines.at(i))
  let end = i
  for j in range(i + 1, lines.len()) {
    let line = lines.at(j)
    if line.trim() == "" { continue }
    // A brace on a line of its own at the item's depth opens its body,
    // in the style that puts it there (as PostgreSQL's C does).
    if indent-of(line) == depth and line.trim() == "{" {
      end = j
      continue
    }
    if indent-of(line) <= depth {
      let closes = (")", "]", "}").any(c => line.trim().starts-with(c))
      if closes and indent-of(line) == depth { end = j }
      break
    }
    end = j
  }
  end
}

// The lines `snippet` shows of a file, and the index of the first.
#let select(path, from: none, through: none, to: none, comments: false) = {
  let lines = read(path).split("\n")
  if lines.len() > 0 and lines.last() == "" { lines = lines.slice(0, -1) }
  let start = 0
  let end = lines.len() - 1
  if from != none {
    let head = 0
    (start, head) = if type(from) == int {
      assert(
        1 <= from and from <= lines.len(),
        message: "line " + str(from) + " is not in " + path,
      )
      (from - 1, from - 1)
    } else {
      let parts = from.split("\n")
      let matches = range(lines.len() - parts.len() + 1).filter(i => {
        parts.enumerate().all(((k, part)) => lines.at(i + k).contains(part))
      })
      assert(
        matches.len() == 1,
        message: "`"
          + from
          + "` is on "
          + str(matches.len())
          + " lines of "
          + path
          + ", not one",
      )
      // The item starts on the line `from`'s last part is on.
      (matches.first(), matches.first() + parts.len() - 1)
    }
    let last = if through != none { through } else { to }
    if last != none {
      let found = if type(last) == int {
        assert(
          head < last and last <= lines.len(),
          message: "line "
            + str(last)
            + " is not after line "
            + str(head + 1)
            + " in "
            + path,
        )
        last - 1
      } else {
        let after = range(head, lines.len()).filter(i => lines
          .at(i)
          .contains(last))
        assert(
          after.len() > 0,
          message: "no `"
            + last
            + "` after line "
            + str(head + 1)
            + " in "
            + path,
        )
        after.first()
      }
      end = if through != none { item-end(lines, found) } else { found }
    } else {
      end = item-end(lines, head)
    }
    if comments {
      while (
        start > 0
          and comment-prefixes.any(p => lines
            .at(start - 1)
            .trim()
            .starts-with(p))
      ) {
        start -= 1
      }
    }
  }
  (start, lines.slice(start, end + 1))
}

// The lines, all shifted left as far as the least indented allows.
#let dedent(..groups) = {
  let indents = groups
    .pos()
    .flatten()
    .filter(line => line.trim() != "")
    .map(indent-of)
  let indent = if indents.len() == 0 { 0 } else { calc.min(..indents) }
  groups
    .pos()
    .map(lines => lines.map(line => line.slice(calc.min(indent, line.len()))))
}

// The name `path` is labelled by, checked against every other file shown.
#let record(path) = {
  let name = path.split("/").last()
  context {
    let earlier = shown.get().at(name, default: path)
    assert(
      earlier == path,
      message: "`" + name + "` names both " + earlier + " and " + path,
    )
  }
  shown.update(names => names + ((name): path))
  name
}

#let language(path, lang) = if lang == auto { path.split(".").last() } else {
  lang
}

// A line of code as a diff shows it: inline raw text, labelled so that
// `listings` doesn't set it on a panel as it does inline code in prose.
#let code-line(text, lang) = [#raw(text, lang: lang)<code-line>]

#let snippet(
  path,
  from: none,
  through: none,
  to: none,
  comments: false,
  lang: auto,
) = {
  let (start, body) = select(
    path,
    from: from,
    through: through,
    to: to,
    comments: comments,
  )
  let (body,) = dedent(body)
  let name = record(path)
  first-line.update(start + 1)
  file-label.update(name)
  raw(body.join("\n"), block: true, lang: language(path, lang))
  first-line.update(1)
  file-label.update(none)
}

// Code blocks sit on a light panel, with line numbers right-aligned in a
// column as wide as the block's last one, and the file's name, if it came
// from one, in the top-right corner, both small and grey. Each line's body
// is boxed in the rest of the width, so a line too long for it wraps under
// itself rather than under the numbers.
#let aside(body) = text(
  font: "DejaVu Sans Mono",
  size: 0.7em,
  fill: luma(55%),
  body,
)

#let listings(doc) = {
  // Tabs as wide as PostgreSQL's C is aligned for (Typst's default is 2).
  set raw(tab-size: 4)
  // Inline code in prose sits on a small panel like a snippet's.
  show raw.where(block: false): it => if (
    it.at("label", default: none) == <code-line>
  ) {
    it
  } else {
    box(fill: luma(96%), inset: (x: 2pt), outset: (y: 2.5pt), radius: 2pt, it)
  }
  show raw.where(block: true): it => context {
    let offset = first-line.get() - 1
    let label = file-label.get()
    let width = measure(aside(str(it.lines.len() + offset))).width
    show raw.line: line => {
      box(width: width, align(right, aside(str(line.number + offset))))
      h(1em)
      box(width: 1fr, line.body)
    }
    // Its numbers start 4pt in, as a diff's do.
    block(
      fill: luma(96%),
      inset: (left: 4pt, rest: 8pt),
      radius: 3pt,
      width: 100%,
      {
        if label != none {
          place(top + right, dy: -4pt, dx: 4pt, aside(label))
        }
        it
      },
    )
  }
  doc
}

// Shows how a part of one file becomes a part of another, as Sampson's
// post shows his flattening: `old` and `new` are each a dictionary with a
// `path` and any of `snippet`'s `from`, `through`, `to` and `comments`.
// Lines are paired by a longest common subsequence; each keeps its line
// number in its own file, and the block is labelled with both names.
// Side by side if both sides' lines fit beside each other, and otherwise
// in one column, a removed line above the line that replaces it;
// `split: true` or `split: false` chooses.
#let diff(old, new, split: auto, lang: auto) = {
  let side(spec) = {
    let named = spec
      .keys()
      .filter(k => k != "path")
      .map(k => (k, spec.at(k)))
      .to-dict()
    select(spec.path, ..named)
  }
  let (a-start, a) = side(old)
  let (b-start, b) = side(new)
  let (a, b) = dedent(a, b)
  let lang = language(new.path, lang)
  let old-name = record(old.path)
  let new-name = record(new.path)
  // lcs.at(i).at(j): how many lines `a` from `i` and `b` from `j` share.
  let lcs = range(a.len() + 1).map(_ => range(b.len() + 1).map(_ => 0))
  for i in range(a.len() - 1, -1, step: -1) {
    for j in range(b.len() - 1, -1, step: -1) {
      lcs.at(i).at(j) = if a.at(i).trim(at: end) == b.at(j).trim(at: end) {
        lcs.at(i + 1).at(j + 1) + 1
      } else {
        calc.max(lcs.at(i + 1).at(j), lcs.at(i).at(j + 1))
      }
    }
  }
  let render(split, left-weight, right-weight) = {
    // Rows of (kept, old line index or none, new line index or none): a
    // line kept has both; a run of removed and added lines between two kept
    // ones is paired up side by side, or, in one column, removed lines first.
    let rows = ()
    let (i, j) = (0, 0)
    let (gone, came) = ((), ())
    let changes(gone, came) = if split {
      range(calc.max(gone.len(), came.len())).map(k => (
        false,
        gone.at(k, default: none),
        came.at(k, default: none),
      ))
    } else {
      gone.map(k => (false, k, none)) + came.map(k => (false, none, k))
    }
    while i < a.len() or j < b.len() {
      if (
        i < a.len()
          and j < b.len()
          and a.at(i).trim(at: end) == b.at(j).trim(at: end)
      ) {
        rows += changes(gone, came)
        (gone, came) = ((), ())
        rows.push((true, i, j))
        (i, j) = (i + 1, j + 1)
      } else if (
        j < b.len()
          and (i == a.len() or lcs.at(i).at(j + 1) >= lcs.at(i + 1).at(j))
      ) {
        came.push(j)
        j += 1
      } else {
        gone.push(i)
        i += 1
      }
    }
    rows += changes(gone, came)
    let kept-fill = luma(96%)
    let removed = rgb("#fbe2e2")
    let added = rgb("#dff3df")
    let absent = luma(91%)
    // Numbers at the size `listings` sets them, inside code: the size of
    // raw text, which Typst sets at 0.8em.
    let number(start, k) = if k == none { [] } else {
      align(right, text(size: 0.8em, aside(str(start + k + 1))))
    }
    // A line too long for its column wraps under its own indentation.
    let code(lines, k) = if k == none { [] } else {
      let line = lines.at(k)
      context par(
        leading: 0.4em,
        hanging-indent: (indent-of(line) + 2)
          * measure(code-line(" ", lang)).width,
        code-line(line, lang),
      )
    }
    let cells = ()
    for (kept, k, l) in rows {
      if split {
        let left = if k == none { absent } else if kept { kept-fill } else {
          removed
        }
        let right = if l == none { absent } else if kept { kept-fill } else {
          added
        }
        cells += (
          table.cell(fill: left, number(a-start, k)),
          table.cell(fill: left, code(a, k)),
          table.cell(fill: right, number(b-start, l)),
          table.cell(fill: right, code(b, l)),
        )
      } else {
        let fill = if kept { kept-fill } else if l == none { removed } else {
          added
        }
        cells += (
          table.cell(fill: fill, number(a-start, k)),
          table.cell(fill: fill, number(b-start, l)),
          table.cell(fill: fill, if l == none { code(a, k) } else {
            code(b, l)
          }),
        )
      }
    }
    // A name sits with room around it in its corner, as a snippet's does.
    let name(body, ..span) = table.cell(
      ..span,
      inset: (top: 5pt, right: 6pt, bottom: 5pt, left: 4pt),
      align(right, text(size: 0.8em, aside(body))),
    )
    let header = if split {
      // Each name over its code alone: a cell spanning the numbers too
      // would widen their column to fit it.
      ([], name(old-name), [], name(new-name))
    } else {
      (name(colspan: 3, old-name + " → " + new-name),)
    }
    // No panel around it: the rows' colours run to the edges of the text.
    // Clipped to a snippet's rounded corners.
    block(radius: 3pt, clip: true, table(
      columns: if split {
        (auto, left-weight * 1fr, auto, right-weight * 1fr)
      } else { (auto, auto, 1fr) },
      stroke: none,
      fill: kept-fill,
      inset: (x: 4pt, y: 2pt),
      table.header(..header),
      ..cells,
      // Room below the last line, in the panel's grey whatever that line
      // is, as a snippet has below its own.
      table.cell(
        colspan: if split { 4 } else { 3 },
        inset: (top: 6pt, rest: 0pt),
        [],
      ),
    ))
  }
  // Side by side, each side gets as much of the width as its widest line
  // needs (with its cells' insets), and they share what is left over; if
  // the two together don't fit, they share the width in proportion to
  // what each needs, and wrap alike.
  layout(size => {
    let inset = 8pt
    let widest(lines) = (
      calc.max(0pt, ..lines.map(line => measure(code-line(line, lang)).width))
        + inset
    )
    let numbers(start, lines) = (
      measure(text(size: 0.8em, aside(str(start + lines.len())))).width + inset
    )
    let (need-a, need-b) = (widest(a), widest(b))
    let room = size.width - numbers(a-start, a) - numbers(b-start, b)
    let fits = need-a + need-b <= room
    let (left, right) = if fits {
      let spare = (room - need-a - need-b) / 2
      (need-a + spare, need-b + spare)
    } else {
      (need-a, need-b)
    }
    render(if split == auto { fits } else { split }, left / 1pt, right / 1pt)
  })
}

// A grammar, one rule per entry: its name, its metavariable, and its
// alternatives. Each alternative is an array of pieces written on one
// line, separated by `|`; each further alternative starts a new line.
#let bnf(..rules) = {
  set par(justify: false)
  // Terminals as plain monospace text, rather than on the panel that
  // `listings` gives inline code in prose.
  show raw.where(block: false): it => text(
    font: "DejaVu Sans Mono",
    size: 0.9em,
    it.text,
  )
  grid(
    columns: 4,
    column-gutter: 0.6em,
    row-gutter: 0.65em,
    align: (left, right, center, left),
    ..rules
      .pos()
      .map(((name, var, ..lines)) => lines
        .enumerate()
        .map(((i, alts)) => {
          let alts = alts.join(h(0.4em) + $|$ + h(0.4em))
          if i == 0 { (text(style: "italic", name), var, $::=$, alts) } else {
            ([], [], $|$, alts)
          }
        })
        .flatten())
      .flatten(),
  )
}

// An optional part of an alternative in `bnf`, in grey parentheses that
// are the grammar's own rather than the language's.
#let opt(body) = {
  let paren(c) = text(fill: luma(50%), c)
  $paren(\() #body paren(\))^?$
}

// A sequence of what's under the line, in `bnf`, which may be empty.
#let seq(body) = $overline(#body)$

// The title page conventional for a CMU SCS thesis proposal, as the old
// `cmuthesis.cls` lays it out, on a page of its own: `committee` is an
// array of `(name, affiliation)` pairs, with a role like "Chair" written
// into the name, in two columns; a single member's affiliation can be
// `none`, and with no members at all the heading is left out too. The
// `date` (a `datetime`) is optional; without one, neither it nor the
// copyright line, which needs its year, is shown.
#let title-page(
  title: none,
  author: none,
  date: none,
  department: (
    [Software and Societal Systems Department],
    [School of Computer Science],
    [Carnegie Mellon University],
    [Pittsburgh, PA 15213],
  ),
  degree: [Doctor of Philosophy in Software Engineering],
  committee: (),
  copyright: true,
) = page(numbering: none, align(center, {
  v(1fr)
  text(1.2em)[Thesis Proposal]
  v(0.6em)
  text(1.8em, weight: "bold", title)
  v(2em)
  text(1.2em, author)
  v(1.2em)
  department.join(linebreak())
  if date != none {
    v(1.2em)
    date.display("[month repr:long] [year]")
  }
  v(2em)
  emph[Submitted in partial fulfillment of the requirements \ for the degree of #degree.]
  if committee.len() > 0 {
    v(2em)
    strong[Thesis Committee]
    v(0.6em)
    grid(
      columns: if committee.len() == 1 { 1 } else { 2 },
      column-gutter: 3em,
      row-gutter: 1.2em,
      ..committee.map(((name, affiliation)) => {
        name
        if affiliation != none {
          linebreak()
          text(0.85em, affiliation)
        }
      }),
    )
  }
  v(2fr)
  if copyright and date != none {
    text(0.85em)[Copyright © #date.year() #author]
  }
}))

// A citation naming the authors in the running text, as natbib's `\citet`.
#let citet(key) = cite(key, form: "prose")

// The document's styling, as `#show: style`: Moss highlighting, `listings`
// for code, and block quotes set off by a grey rule on the left.
#let style(doc) = {
  set raw(syntaxes: "syntaxes/moss.sublime-syntax")
  show quote.where(block: true): it => block(
    width: 100%,
    stroke: (left: 2pt + luma(75%)),
    outset: (left: -0.4em, y: 0.5em),
    it,
  )
  show: listings
  doc
}
