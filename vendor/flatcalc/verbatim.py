"""Check that items of Sampson's flatcalc appear verbatim in our examples.

Usage: verbatim.py THEIRS OURS ANCHOR...

Each ANCHOR is text on exactly one line of THEIRS, where an item starts.
The item runs, as `snippet.typ` takes it, from that line through the
first later line indented no deeper (included if it is at the same depth
and closes a bracket), and takes the comment and attribute lines directly
above it. Each item must appear in OURS as a run of whole lines, at any
indentation as long as every line is shifted alike.
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
    while start > 0 and lines[start - 1].strip().startswith(("//", "#")):
        start -= 1
    return lines[start : end + 1]


def dedent(block):
    shift = min(indent(line) for line in block if line.strip())
    return [line[shift:] for line in block]


def main():
    theirs_path, ours_path, *anchors = sys.argv[1:]
    theirs = open(theirs_path).read().split("\n")
    ours = open(ours_path).read().split("\n")
    failed = False
    for anchor in anchors:
        want = dedent(item(theirs, anchor))
        found = any(
            all(line.strip() == "" for line in ours[i : i + len(want)]) is False
            and dedent(ours[i : i + len(want)]) == want
            for i in range(len(ours) - len(want) + 1)
        )
        print(f"{'ok' if found else 'MISSING'}: `{anchor}` ({len(want)} lines)")
        failed |= not found
    if failed:
        sys.exit(f"{ours_path} does not contain {theirs_path}'s items verbatim")


main()
