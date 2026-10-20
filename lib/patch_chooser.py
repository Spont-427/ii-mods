#!/usr/bin/env python3
"""Copy an existing DelegateChoice block in AndroidToggleDelegateChooser.qml
and turn the copy into a choice for a new toggle.

usage: patch_chooser.py <file> <new_role> <NewComponent> <copy_after_role>
"""
import re
import sys

path, role, comp, after = sys.argv[1:5]

with open(path, encoding="utf-8") as fh:
    lines = fh.read().split("\n")

start = next(
    (i for i, line in enumerate(lines)
     if re.search(r'roleValue:\s*"%s"' % re.escape(after), line)),
    None,
)
if start is None:
    sys.exit(f'could not find a DelegateChoice for "{after}" in {path}')

# Find the end of the block by counting braces.
depth, seen, end = 0, False, None
for i in range(start, len(lines)):
    for ch in lines[i]:
        if ch == "{":
            depth += 1
            seen = True
        elif ch == "}":
            depth -= 1
    if seen and depth == 0:
        end = i
        break
if end is None:
    sys.exit("unbalanced braces while reading the existing DelegateChoice")

block = lines[start:end + 1]
first = block[0]
block[0] = re.sub(
    r'(roleValue:\s*")[^"]+(";\s*)\w+',
    lambda m: f"{m.group(1)}{role}{m.group(2)}{comp}",
    first,
    count=1,
)
if block[0] == first:
    sys.exit("the existing DelegateChoice has an unexpected layout; add the entry by hand (see README)")

indent = re.match(r"\s*", lines[start]).group(0)
new = [f"{indent}// ii-mods:{role} begin"] + block + [f"{indent}// ii-mods:{role} end"]
lines[end + 1:end + 1] = new

with open(path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))
