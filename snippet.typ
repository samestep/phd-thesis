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

#let snippet(path, from: none, through: none, to: none, comments: false, lang: auto) = {
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
  let body = lines.slice(start, end + 1)
  let indents = body.filter(line => line.trim() != "").map(indent-of)
  let indent = if indents.len() == 0 { 0 } else { calc.min(..indents) }
  let text = body.map(line => line.slice(calc.min(indent, line.len()))).join("\n")
  let name = path.split("/").last()
  context {
    let earlier = shown.get().at(name, default: path)
    assert(earlier == path, message: "`" + name + "` names both " + earlier + " and " + path)
  }
  shown.update(names => names + ((name): path))
  first-line.update(start + 1)
  file-label.update(name)
  raw(text, block: true, lang: if lang == auto { path.split(".").last() } else { lang })
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
