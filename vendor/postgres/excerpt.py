"""Check that functions of ours are PostgreSQL's with only lines removed.

Usage: excerpt.py THEIRS OURS NAME...

Each NAME is a C function defined in both files, in PostgreSQL's style:
the return type on one line, then the name at the start of the next, then
the body in braces starting at the start of a line. Apart from that first
line, its parameters, every line of our function must be a line of theirs,
in the same order, compared without leading or trailing whitespace and
with each run of whitespace inside taken as one space. A line that is only
a brace is exempt, since dropping an `if` or `else` around lines (as ours
drop PostgreSQL's aggregate plumbing) leaves its braces unmatched. So
ours may leave lines out, but can't add, change or reorder any.
"""

import sys


def function(lines, name, path):
    starts = [i for i, line in enumerate(lines) if line.startswith(name + "(")]
    if len(starts) != 1:
        sys.exit(f"`{name}` is defined on {len(starts)} lines of {path}, not one")
    start = starts[0]
    for end in range(start + 1, len(lines)):
        if lines[end] == "}":
            return lines[start + 1 : end + 1]
    sys.exit(f"`{name}` in {path} has no closing brace")


def normal(line):
    return " ".join(line.split())


def main():
    theirs_path, ours_path, *names = sys.argv[1:]
    theirs = open(theirs_path).read().split("\n")
    ours = open(ours_path).read().split("\n")
    failed = False
    for name in names:
        want = [normal(line) for line in function(theirs, name, theirs_path)]
        missing = None
        i = 0
        for line in function(ours, name, ours_path):
            line = normal(line)
            if line in ("", "{", "}"):
                continue
            while i < len(want) and want[i] != line:
                i += 1
            if i == len(want):
                missing = line
                break
            i += 1
        print(f"{'ok' if missing is None else 'NOT THEIRS'}: `{name}`")
        if missing is not None:
            print(f"  `{missing}` isn't a line of theirs, or is out of order")
            failed = True
    if failed:
        sys.exit(f"{ours_path} changes {theirs_path}'s functions beyond removing lines")


main()
