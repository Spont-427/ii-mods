#!/usr/bin/env python3
"""Add a child object at the end of a QML file's root object.

usage: qml_inject.py <file.qml> <id> <snippet-file>

The snippet is inserted just before the last closing brace of the file (which
closes the root object), wrapped in  // ii-mods:<id> begin / end  markers so
it can be found and removed again. Running it twice does nothing.
"""
import sys

path, ident, snippet_path = sys.argv[1:4]

with open(path, encoding="utf-8") as fh:
    lines = fh.read().split("\n")

begin = f"// ii-mods:{ident} begin"
if any(begin in line for line in lines):
    print("already injected")
    sys.exit(0)

last = next((i for i in range(len(lines) - 1, -1, -1) if lines[i].strip() == "}"), None)
if last is None:
    sys.exit("could not find the closing brace of the root object")

with open(snippet_path, encoding="utf-8") as fh:
    snippet = fh.read().rstrip("\n").split("\n")

block = [f"    {begin}"] + [("    " + l if l.strip() else l) for l in snippet] + [f"    // ii-mods:{ident} end"]
lines[last:last] = block

with open(path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))
print("injected")
