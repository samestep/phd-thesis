// Shows a code example from `examples/`, which `nix flake check` runs.
//
// With `region`, only the lines between a `region: <name>` marker and its
// matching `endregion` marker, in whatever comment syntax the file uses.
// Marker lines are always dropped, and the result is dedented. The
// language for highlighting defaults to the file's extension.
#let snippet(path, region: none, lang: auto) = {
  let lines = read(path).split("\n")
  let opens(line) = line.contains(regex("\bregion: [\w-]+"))
  let closes(line) = line.contains(regex("\bendregion\b"))
  if region != none {
    let start = lines.position(line => line.contains(regex("\bregion: " + region + "\b")))
    assert(start != none, message: "no region `" + region + "` in " + path)
    let rest = lines.slice(start + 1)
    let depth = 0
    let end = none
    for (i, line) in rest.enumerate() {
      if closes(line) {
        if depth == 0 {
          end = i
          break
        }
        depth -= 1
      } else if opens(line) {
        depth += 1
      }
    }
    assert(end != none, message: "region `" + region + "` in " + path + " never ends")
    lines = rest.slice(0, end)
  }
  lines = lines.filter(line => not opens(line) and not closes(line))
  while lines.len() > 0 and lines.first().trim() == "" { lines = lines.slice(1) }
  while lines.len() > 0 and lines.last().trim() == "" { lines = lines.slice(0, -1) }
  let indents = lines.filter(line => line.trim() != "").map(line => line.len() - line.trim(at: start).len())
  let indent = if indents.len() == 0 { 0 } else { calc.min(..indents) }
  let text = lines.map(line => line.slice(calc.min(indent, line.len()))).join("\n")
  raw(text, block: true, lang: if lang == auto { path.split(".").last() } else { lang })
}
