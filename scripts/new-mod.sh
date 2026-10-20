#!/usr/bin/env bash
# Create a new mod folder from the template.
#   ./scripts/new-mod.sh my-cool-mod
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:-}"

[[ -n $name ]] || { echo "usage: $0 <mod-name>   (lowercase letters, digits and dashes)" >&2; exit 64; }
[[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "Use only lowercase letters, digits and dashes." >&2; exit 64; }
[[ ! -e $REPO_DIR/mods/$name ]] || { echo "mods/$name already exists." >&2; exit 1; }

cp -r "$REPO_DIR/mods/_template" "$REPO_DIR/mods/$name"
sed -i "s/__MOD_NAME__/$name/g" "$REPO_DIR/mods/$name/mod.sh" "$REPO_DIR/mods/$name/README.md"

echo "Created mods/$name"
echo "Next:"
echo "  1. put new/changed QML files under mods/$name/files/ (mirror ~/.config/quickshell/ii)"
echo "  2. edit mods/$name/mod.sh if you need extra steps"
echo "  3. test:  ./install.sh $name   and   ./install.sh --uninstall $name"
