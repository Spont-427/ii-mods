# shellcheck shell=bash
# Shared helpers for install.sh and every mods/*/mod.sh.
# This file is sourced, never executed directly.

# ---------------------------------------------------------------- colours --
if [[ -t 1 ]]; then
  C_RED=$'\e[31m'; C_GRN=$'\e[32m'; C_YEL=$'\e[33m'; C_BLU=$'\e[34m'; C_OFF=$'\e[0m'
else
  C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_OFF=""
fi

info()  { printf '%s[ii-mods]%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()    { printf '%s[ ok ]%s %s\n'    "$C_GRN" "$C_OFF" "$*"; }
warn()  { printf '%s[warn]%s %s\n'    "$C_YEL" "$C_OFF" "$*" >&2; }
die()   { printf '%s[fail]%s %s\n'    "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

# ---------------------------------------------------------------- prompts --
# ASSUME_YES=1 (the --yes flag) or a non-interactive shell means "use the default".

# ask "Question?" y|n   -> returns 0 for yes, 1 for no
ask() {
  local question=$1 default=${2:-n} reply hint="[y/N]"
  [[ $default == y ]] && hint="[Y/n]"
  if [[ ${ASSUME_YES:-0} == 1 || ! -t 0 ]]; then
    [[ $default == y ]]
    return
  fi
  read -r -p "$question $hint " reply || true
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy] ]]
}

# prompt_text "Label" "default"  -> prints the answer
prompt_text() {
  local label=$1 default=$2 reply
  if [[ ${ASSUME_YES:-0} == 1 || ! -t 0 ]]; then
    printf '%s' "$default"
    return
  fi
  read -r -p "$label [$default]: " reply || true
  printf '%s' "${reply:-$default}"
}

# prompt_secret "Label"  -> prints the answer (nothing is echoed while typing)
prompt_secret() {
  local label=$1 reply
  if [[ ${ASSUME_YES:-0} == 1 || ! -t 0 ]]; then
    return
  fi
  read -r -s -p "$label: " reply || true
  echo >&2
  printf '%s' "$reply"
}

# ----------------------------------------------------------- dependencies --
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1 — ${2:-please install it first}"; }
need_file() { [[ -f $1 ]] || die "Missing file: $1 — ${2:-is the dotfile layout different on your system?}"; }

# ---------------------------------------------------- manifests & backups --
# Every file a mod copies onto your system is recorded in a manifest so that
# uninstall can remove exactly those files (and restore anything we replaced).

manifest_file() { printf '%s/manifests/%s.list' "$STATE_DIR" "$1"; }

in_manifest() {
  local f; f=$(manifest_file "$1")
  [[ -f $f ]] && grep -qxF -- "$2" "$f"
}

manifest_add() {
  local f; f=$(manifest_file "$1")
  mkdir -p "$(dirname "$f")"
  touch "$f"
  grep -qxF -- "$2" "$f" || printf '%s\n' "$2" >> "$f"
}

# Keep a copy of a file we are about to overwrite for the first time.
backup_original() {
  local mod=$1 target=$2 b="$STATE_DIR/backups/$1$2"
  if [[ -e $target && ! -e $b ]]; then
    mkdir -p "$(dirname "$b")"
    cp -p "$target" "$b"
    info "backed up your existing $(basename "$target")"
  fi
}

# Timestamped snapshot of a file we are going to patch in place.
snapshot_file() {
  local mod=$1 target=$2 dir="$STATE_DIR/snapshots/$1"
  mkdir -p "$dir"
  cp -p "$target" "$dir/$(basename "$target").$(date +%Y%m%d-%H%M%S)"
}

# install_file <mod> <source> <target>
install_file() {
  local mod=$1 src=$2 target=$3
  mkdir -p "$(dirname "$target")"
  if [[ -e $target ]] && ! in_manifest "$mod" "$target"; then
    backup_original "$mod" "$target"
  fi
  cp -p "$src" "$target"
  manifest_add "$mod" "$target"
  ok "installed $target"
}

# install_tree <mod> <source_dir> <dest_root>
# Copies every file below source_dir to the same relative path below dest_root.
install_tree() {
  local mod=$1 src=$2 dest=$3 f rel
  [[ -d $src ]] || return 0
  while IFS= read -r -d '' f; do
    rel=${f#"$src"/}
    [[ $(basename "$rel") == .gitkeep ]] && continue
    install_file "$mod" "$f" "$dest/$rel"
  done < <(find "$src" -type f -print0)
}

# Remove everything a mod installed; put back anything it replaced.
uninstall_files() {
  local mod=$1 mf f b
  mf=$(manifest_file "$mod")
  if [[ ! -f $mf ]]; then
    warn "no record of installed files for '$mod' (nothing to remove)"
    return 0
  fi
  while IFS= read -r f; do
    [[ -z $f ]] && continue
    b="$STATE_DIR/backups/$mod$f"
    if [[ -e $b ]]; then
      cp -p "$b" "$f"
      ok "restored your original $f"
    else
      rm -f "$f"
      ok "removed $f"
    fi
  done < "$mf"
  rm -f "$mf"
  rm -rf "${STATE_DIR:?}/backups/$mod"
}

# ------------------------------------------------------- patching helpers --
CHOOSER_REL="modules/ii/sidebarRight/quickToggles/androidStyle/AndroidToggleDelegateChooser.qml"

# patch_delegate_chooser <mod> <role> <ComponentName> <copy_after_role>
# Adds a  DelegateChoice { roleValue: "<role>"; <ComponentName> {...} }  block
# next to an existing one so the sidebar knows how to draw the new tile.
patch_delegate_chooser() {
  local mod=$1 role=$2 comp=$3 after=$4
  local file="$QS_DIR/$CHOOSER_REL"
  need_file "$file"
  if grep -q "ii-mods:$role begin" "$file"; then
    ok "sidebar chooser already patched for '$role'"
    return 0
  fi
  if grep -q "roleValue: \"$role\"" "$file"; then
    warn "'$role' already exists in $(basename "$file") (added by hand?) — leaving it alone"
    return 0
  fi
  snapshot_file "$mod" "$file"
  python3 "$LIB_DIR/patch_chooser.py" "$file" "$role" "$comp" "$after"
  ok "patched $(basename "$file") with '$role'"
}

unpatch_delegate_chooser() {
  local role=$1 file="$QS_DIR/$CHOOSER_REL"
  [[ -f $file ]] || return 0
  if grep -q "ii-mods:$role begin" "$file"; then
    sed -i "/ii-mods:$role begin/,/ii-mods:$role end/d" "$file"
    ok "removed '$role' from $(basename "$file")"
  fi
}

# config_toggle add|remove <mod> <type> [copy_after_type]
config_toggle() {
  local action=$1 mod=$2 type=$3 after=${4:-}
  if [[ ! -f $II_CONFIG ]]; then
    warn "$II_CONFIG not found yet — start the shell once, then run this again (or add the tile with the pencil icon)"
    return 0
  fi
  snapshot_file "$mod" "$II_CONFIG"
  python3 "$LIB_DIR/json_toggle.py" "$action" "$II_CONFIG" "$type" ${after:+"$after"}
}
