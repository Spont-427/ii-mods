#!/usr/bin/env bash
# ii-mods installer — installs / removes personal mods for end-4's
# illogical-impulse (Quickshell "ii") Hyprland dotfiles.
#
#   ./install.sh                     install every mod (asks first)
#   ./install.sh hotspot-toggle      install one mod
#   ./install.sh --list              show available mods
#   ./install.sh --uninstall NAME    remove a mod (or --uninstall for all)
#   ./install.sh --yes ...           never ask questions, use defaults
#
# Safe to run again: everything is idempotent, so run it after every update of
# the end-4 dotfiles to re-apply your mods.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$REPO_DIR/lib"
MODS_DIR="$REPO_DIR/mods"

# Where things live. Override with environment variables if yours differ.
QS_DIR="${II_QS_DIR:-$HOME/.config/quickshell/ii}"
II_CONFIG="${II_CONFIG_JSON:-$HOME/.config/illogical-impulse/config.json}"
BIN_DIR="${II_BIN_DIR:-$HOME/.local/bin}"
STATE_DIR="${II_MODS_STATE:-$HOME/.local/state/ii-mods}"
ASSUME_YES=0

export REPO_DIR LIB_DIR MODS_DIR QS_DIR II_CONFIG BIN_DIR STATE_DIR ASSUME_YES

# shellcheck source=lib/helpers.sh
source "$LIB_DIR/helpers.sh"

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

list_mods() {
  find "$MODS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -printf '%f\n' | sort
}

mod_description_of() {
  ( # shellcheck source=/dev/null
    source "$MODS_DIR/$1/mod.sh"
    declare -F mod_description >/dev/null && mod_description || echo "(no description)" )
}

# Run an optional hook function from a mod's mod.sh inside a subshell.
run_hook() {
  local mod=$1 hook=$2
  (
    # shellcheck source=/dev/null
    source "$MODS_DIR/$mod/mod.sh"
    if declare -F "$hook" >/dev/null; then "$hook"; fi
  )
}

install_mod() {
  local mod=$1
  [[ -f $MODS_DIR/$mod/mod.sh ]] || die "No such mod: '$mod' (try ./install.sh --list)"
  info "=== installing $mod ==="
  run_hook "$mod" mod_check || die "pre-flight check failed for '$mod'"
  install_tree "$mod" "$MODS_DIR/$mod/files" "$QS_DIR"
  install_tree "$mod" "$MODS_DIR/$mod/bin"   "$BIN_DIR"
  run_hook "$mod" mod_post_install || die "post-install step failed for '$mod'"
  ok "$mod installed"
}

uninstall_mod() {
  local mod=$1
  [[ -f $MODS_DIR/$mod/mod.sh ]] || die "No such mod: '$mod'"
  info "=== uninstalling $mod ==="
  run_hook "$mod" mod_pre_uninstall || warn "pre-uninstall step reported a problem"
  uninstall_files "$mod"
  ok "$mod uninstalled"
}

# -------------------------------------------------------------- arguments --
ACTION=install
SELECTED=()
while (($#)); do
  case $1 in
    -h|--help)      usage; exit 0 ;;
    -l|--list)      ACTION=list ;;
    -u|--uninstall) ACTION=uninstall ;;
    -y|--yes)       ASSUME_YES=1; export ASSUME_YES ;;
    -*)             die "Unknown option: $1 (see --help)" ;;
    *)              SELECTED+=("$1") ;;
  esac
  shift
done

if [[ $ACTION == list ]]; then
  while IFS= read -r m; do printf '  %-20s %s\n' "$m" "$(mod_description_of "$m")"; done < <(list_mods)
  exit 0
fi

command -v python3 >/dev/null || die "python3 is required (sudo pacman -S python)"
[[ -d $QS_DIR ]] || die "Could not find the illogical-impulse shell at $QS_DIR.
       Install end-4's dotfiles first, or point at yours:  II_QS_DIR=/path/to/ii ./install.sh"

if ((${#SELECTED[@]} == 0)); then
  mapfile -t SELECTED < <(list_mods)
  info "No mod named — that means: ${SELECTED[*]}"
  ask "Continue?" y || { info "Nothing done."; exit 0; }
fi

for mod in "${SELECTED[@]}"; do
  if [[ $ACTION == install ]]; then install_mod "$mod"; else uninstall_mod "$mod"; fi
done

echo
ok "All done."
info "Quickshell normally reloads by itself. If you don't see the change, restart it:"
info "    killall qs; qs -c ii & disown"
