#!/usr/bin/env python3
"""Add or remove a quick-toggle id in illogical-impulse's config.json.

usage: json_toggle.py add    <config.json> <type> <copy_after_type>
       json_toggle.py remove <config.json> <type>

The Android-style layout stores objects like {"size": 1, "type": "nightLight"}.
`add` only touches those lists (wherever they are in the file, so it keeps
working if key names change). The classic layout stores plain strings; this mod
does not support it, so `add` leaves those lists alone, while `remove` cleans
up both kinds.
"""
import json
import os
import sys

action, path, new = sys.argv[1:4]
after = sys.argv[4] if len(sys.argv) > 4 else None

with open(path, encoding="utf-8") as fh:
    data = json.load(fh)


def all_lists(node):
    if isinstance(node, list):
        yield node
        for item in node:
            yield from all_lists(item)
    elif isinstance(node, dict):
        for value in node.values():
            yield from all_lists(value)


changed = 0
for lst in list(all_lists(data)):
    if action == "add":
        if any(isinstance(x, dict) and x.get("type") == new for x in lst):
            continue
        for i, x in enumerate(lst):
            if isinstance(x, dict) and x.get("type") == after:
                clone = dict(x)
                clone["type"] = new
                lst.insert(i + 1, clone)
                changed += 1
                break
    else:  # remove
        keep = [x for x in lst if not ((isinstance(x, dict) and x.get("type") == new) or x == new)]
        if len(keep) != len(lst):
            lst[:] = keep
            changed += 1

if changed:
    tmp = path + ".ii-mods.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=4, ensure_ascii=False)
        fh.write("\n")
    os.replace(tmp, path)
    print(f"[ ok ] config.json: {action} '{new}' ({changed} list(s) changed)")
else:
    print(f"[ ok ] config.json: nothing to do for '{new}'")
