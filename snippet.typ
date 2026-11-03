// Shows code from `examples/`, which `nix flake check` runs, numbered as
// the lines are numbered in the file and labelled with the file's name.
//
// Without `from`, the whole file. With `from`, the one line containing
// that text, through the end of the item it starts: the first later line
// indented no deeper, included if it is at the same depth and closes a
// bracket (as `}` does) and excluded otherwise (as for an
// indentation-delimited language, or the end of an enclosing block). With
// `through`, instead through the end of the item starting at the first
// later line containing that text; with `to`, through that line itself. With
// `comments: true`, also the comment lines directly above. Each pattern
// is plain text, and `from` must match exactly one line, so that a file
// changing under the document fails the build rather than silently
// showing something else. The result is dedented, and the language for
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
    let matches = range(lines.len()).filter(i => lines.at(i).contains(from))
    assert(matches.len() == 1, message: "`" + from + "` is on " + str(matches.len()) + " lines of " + path + ", not one")
    start = matches.first()
    let last = if through != none { through } else { to }
    if last != none {
      let after = range(start, lines.len()).filter(i => lines.at(i).contains(last))
      assert(after.len() > 0, message: "no `" + last + "` after `" + from + "` in " + path)
      end = if through != none { item-end(lines, after.first()) } else { after.first() }
    } else {
      end = item-end(lines, start)
    }
    if comments {
      while start > 0 and comment-prefixes.any(p => lines.at(start - 1).trim().starts-with(p)) {
        start -= 1
      }
    }
  }
  (start, lines.slice(start, end + 1))
}

// The lines, all shifted left as far as the least indented allows.
#let dedent(..groups) = {
  let indents = groups.pos().flatten().filter(line => line.trim() != "").map(indent-of)
  let indent = if indents.len() == 0 { 0 } else { calc.min(..indents) }
  groups.pos().map(lines => lines.map(line => line.slice(calc.min(indent, line.len()))))
}

// The name `path` is labelled by, checked against every other file shown.
#let record(path) = {
  let name = path.split("/").last()
  context {
    let earlier = shown.get().at(name, default: path)
    assert(earlier == path, message: "`" + name + "` names both " + earlier + " and " + path)
  }
  shown.update(names => names + ((name): path))
  name
}

#let language(path, lang) = if lang == auto { path.split(".").last() } else { lang }

#let snippet(path, from: none, through: none, to: none, comments: false, lang: auto) = {
  let (start, body) = select(path, from: from, through: through, to: to, comments: comments)
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
#let aside(body) = text(font: "DejaVu Sans Mono", size: 0.7em, fill: luma(55%), body)

#let listings(doc) = {
  show raw.where(block: true): it => context {
    let offset = first-line.get() - 1
    let label = file-label.get()
    let width = measure(aside(str(it.lines.len() + offset))).width
    show raw.line: line => {
      box(width: width, align(right, aside(str(line.number + offset))))
      h(1em)
      box(width: 1fr, line.body)
    }
    block(fill: luma(96%), inset: 8pt, radius: 3pt, width: 100%, {
      if label != none {
        place(top + right, dy: -4pt, dx: 4pt, aside(label))
      }
      it
    })
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
    let named = spec.keys().filter(k => k != "path").map(k => (k, spec.at(k))).to-dict()
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
      range(calc.max(gone.len(), came.len())).map(k => (false, gone.at(k, default: none), came.at(k, default: none)))
    } else {
      gone.map(k => (false, k, none)) + came.map(k => (false, none, k))
    }
    while i < a.len() or j < b.len() {
      if i < a.len() and j < b.len() and a.at(i).trim(at: end) == b.at(j).trim(at: end) {
        rows += changes(gone, came)
        (gone, came) = ((), ())
        rows.push((true, i, j))
        (i, j) = (i + 1, j + 1)
      } else if j < b.len() and (i == a.len() or lcs.at(i).at(j + 1) >= lcs.at(i + 1).at(j)) {
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
    let number(start, k) = if k == none { [] } else { align(right, text(size: 0.8em, aside(str(start + k + 1)))) }
    // A line too long for its column wraps under its own indentation.
    let code(lines, k) = if k == none { [] } else {
      let line = lines.at(k)
      context par(leading: 0.4em, hanging-indent: (indent-of(line) + 2) * measure(raw(" ")).width, raw(line, lang: lang))
    }
    let cells = ()
    for (kept, k, l) in rows {
      if split {
        let left = if k == none { absent } else if kept { kept-fill } else { removed }
        let right = if l == none { absent } else if kept { kept-fill } else { added }
        cells += (
          table.cell(fill: left, number(a-start, k)),
          table.cell(fill: left, code(a, k)),
          table.cell(fill: right, number(b-start, l)),
          table.cell(fill: right, code(b, l)),
        )
      } else {
        let fill = if kept { kept-fill } else if l == none { removed } else { added }
        cells += (
          table.cell(fill: fill, number(a-start, k)),
          table.cell(fill: fill, number(b-start, l)),
          table.cell(fill: fill, if l == none { code(a, k) } else { code(b, l) }),
        )
      }
    }
    // A name sits with room around it in its corner, as a snippet's does.
    let name(body, ..span) = table.cell(
      ..span,
      inset: (top: 5pt, right: 6pt, bottom: 2pt, left: 4pt),
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
    table(
      columns: if split { (auto, left-weight * 1fr, auto, right-weight * 1fr) } else { (auto, auto, 1fr) },
      stroke: none,
      fill: kept-fill,
      inset: (x: 4pt, y: 2pt),
      table.header(..header),
      ..cells,
    )
  }
  // Side by side, each side gets as much of the width as its widest line
  // needs (with its cells' insets), and they share what is left over; if
  // the two together don't fit, they share the width in proportion to
  // what each needs, and wrap alike.
  layout(size => {
    let inset = 8pt
    let widest(lines) = calc.max(0pt, ..lines.map(line => measure(raw(line, lang: lang)).width)) + inset
    let numbers(start, lines) = measure(text(size: 0.8em, aside(str(start + lines.len())))).width + inset
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
