"""Check that items of Sampson's flatcalc are in our examples, as code.

Usage: verbatim.py THEIRS OURS ANCHOR...

Each ANCHOR is text on exactly one line of THEIRS, where an item starts.
The item runs, as `snippet.typ` takes it, from that line through the
first later line indented no deeper (included if it is at the same depth
and closes a bracket). Its code must appear in OURS, compared without
comments, attributes, whitespace, or a trailing comma before a closing
bracket: so ours may be laid out as his blog post lays it out (`enum BinOp
{ Add, Sub, Mul, Div }`, no `#[derive]`s, no doc comments), but every
other token of it is his. Rust needs whitespace between two tokens only to
keep words apart, as in `let x`, which comes out the same either way, and
a trailing comma never changes what a list means, so neither hides a
difference in the code.
"""

import sys


def indent(line):
    return len(line) - len(line.lstrip())


def item(lines, anchor):
    starts = [i for i, line in enumerate(lines) if anchor in line]
    if len(starts) != 1:
        sys.exit(f"`{anchor}` is on {len(starts)} lines, not one")
    start = end = starts[0]
    depth = indent(lines[start])
    for j in range(start + 1, len(lines)):
        line = lines[j]
        if not line.strip():
            continue
        if indent(line) <= depth:
            if indent(line) == depth and line.strip()[:1] in ")]}":
                end = j
            break
        end = j
    return lines[start : end + 1]


def code(lines):
    """The code in these lines, without comments, attributes or whitespace."""
    out = []
    for line in lines:
        if line.strip().startswith("#["):
            continue
        # Cut a `//` comment, but not `//` inside a string literal.
        in_string = False
        for i, c in enumerate(line):
            if c == '"' and (i == 0 or line[i - 1] != "\\"):
                in_string = not in_string
            elif not in_string and line.startswith("//", i):
                line = line[:i]
                break
        out.append(line)
    flat = "".join("".join(out).split())
    for close in ")]}":
        flat = flat.replace("," + close, close)
    return flat


def main():
    theirs_path, ours_path, *anchors = sys.argv[1:]
    theirs = open(theirs_path).read().split("\n")
    ours = code(open(ours_path).read().split("\n"))
    failed = False
    for anchor in anchors:
        want = code(item(theirs, anchor))
        found = want in ours
        print(f"{'ok' if found else 'MISSING'}: `{anchor}`")
        failed |= not found
    if failed:
        sys.exit(f"{ours_path} does not contain {theirs_path}'s items as code")


main()
