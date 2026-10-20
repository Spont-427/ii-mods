# shellcheck shell=bash
# hotspot-toggle — adds a Wi-Fi hotspot tile to the right sidebar quick toggles.
#
# Sourced by install.sh. Helpers (info, ok, warn, ask, patch_delegate_chooser, …)
# and the variables QS_DIR, II_CONFIG, BIN_DIR, STATE_DIR come from there.
#
# Files in  files/  are copied into  $QS_DIR  (~/.config/quickshell/ii)
# Files in  bin/    are copied into  $BIN_DIR (~/.local/bin)
# Everything else is done by the hooks below.

MOD=hotspot-toggle
WRAPPER_DIR="$QS_DIR/modules/ii/sidebarRight/quickToggles/androidStyle"
HOTSPOT_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ii-mods"
HOTSPOT_CONF="$HOTSPOT_CONF_DIR/hotspot.conf"
SUDOERS_FILE="/etc/sudoers.d/ii-mods-create_ap"

mod_description() {
  echo "Wi-Fi hotspot tile (create_ap) for the right sidebar quick toggles"
}

# Runs before anything is copied.
mod_check() {
  need_file "$WRAPPER_DIR/AndroidCloudflareWarpToggle.qml" \
    "this mod copies the Cloudflare WARP tile as a template; is your end-4 dotfiles version too old/new?"
  need_file "$QS_DIR/$CHOOSER_REL"
  if ! command -v create_ap >/dev/null 2>&1; then
    warn "create_ap is not installed. The tile will be added, but won't work until you install it:"
    warn "    yay -S create_ap        (or: paru -S create_ap)"
  fi
}

# Runs after files/ and bin/ have been copied.
mod_post_install() {
  local src="$WRAPPER_DIR/AndroidCloudflareWarpToggle.qml" tmp

  # 1. Make the Android-style wrapper by copying the Cloudflare one.
  tmp=$(mktemp)
  sed 's/CloudflareWarpToggle/HotspotToggle/g; s/CloudflareWarp/Hotspot/g; s/Cloudflare WARP/Hotspot/g' \
    "$src" > "$tmp"
  install_file "$MOD" "$tmp" "$WRAPPER_DIR/AndroidHotspotToggle.qml"
  rm -f "$tmp"

  # 2. Teach the sidebar about the new tile type.
  patch_delegate_chooser "$MOD" hotspot AndroidHotspotToggle cloudflareWarp

  # 3. Put the tile in the layout (the same as clicking "add" in edit mode).
  config_toggle add "$MOD" hotspot cloudflareWarp

  # 4. Hotspot name / password / interfaces.
  setup_hotspot_conf

  # 5. Let create_ap run via sudo without a password prompt (the toggle has no terminal).
  setup_sudoers
}

mod_pre_uninstall() {
  unpatch_delegate_chooser hotspot
  config_toggle remove "$MOD" hotspot
  if [[ -f $SUDOERS_FILE ]]; then
    if ask "Remove the sudo rule $SUDOERS_FILE?" n; then
      sudo rm -f "$SUDOERS_FILE" && ok "removed $SUDOERS_FILE"
    fi
  fi
  info "Your hotspot settings ($HOTSPOT_CONF) were kept; delete them yourself if you like."
}

# ------------------------------------------------------------------ helpers --

setup_hotspot_conf() {
  if [[ -f $HOTSPOT_CONF ]]; then
    ok "keeping your existing $HOTSPOT_CONF"
    return 0
  fi

  local iface ssid pass
  iface=wlan0
  if command -v iw >/dev/null 2>&1; then
    iface=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2; exit}')
    iface=${iface:-wlan0}
  fi

  info "Hotspot settings (saved only on this computer, in $HOTSPOT_CONF)"
  iface=$(prompt_text "Wi-Fi interface" "$iface")
  ssid=$(prompt_text "Network name (SSID)" "Hyprland")
  pass=""
  while :; do
    pass=$(prompt_secret "Password (8-63 characters, empty = set it later)")
    if [[ -z $pass ]] || (( ${#pass} >= 8 && ${#pass} <= 63 )); then break; fi
    warn "WPA2 passwords must be 8 to 63 characters, try again"
  done

  mkdir -p "$HOTSPOT_CONF_DIR"
  (
    umask 077
    {
      echo "# Written by ii-mods. Edit freely. Never commit this file."
      printf 'WIFI_IFACE=%q\n' "$iface"
      printf 'INET_IFACE=%q\n' "$iface"
      printf 'SSID=%q\n'       "$ssid"
      printf 'PASSWORD=%q\n'   "$pass"
    } > "$HOTSPOT_CONF"
  )
  chmod 600 "$HOTSPOT_CONF"
  ok "wrote $HOTSPOT_CONF"
  [[ -z $pass ]] && warn "No password yet — open $HOTSPOT_CONF and set PASSWORD before using the toggle."
  return 0
}

setup_sudoers() {
  if [[ -f $SUDOERS_FILE ]]; then
    ok "sudo rule already present ($SUDOERS_FILE)"
    return 0
  fi
  if [[ ${ASSUME_YES:-0} == 1 || ! -t 0 ]]; then
    warn "Skipping the sudo rule (non-interactive). Without it the toggle can't start create_ap."
    warn "Re-run ./install.sh hotspot-toggle in a terminal, or see 'Manual steps' in the mod README."
    return 0
  fi

  local bin tmp
  bin=$(command -v create_ap || true)
  if [[ -z $bin ]]; then
    warn "create_ap not found, so the sudo rule can't be written yet. Install it, then re-run this installer."
    return 0
  fi
  bin=$(readlink -f "$bin")

  info "The toggle runs 'sudo create_ap' in the background, which can't type a password."
  info "I can add this rule:   $USER ALL=(root) NOPASSWD: $bin"
  info "It means any program running as you can start/stop create_ap as root without a password."
  if ask "Add the rule now (asks for your sudo password once)?" y; then
    tmp=$(mktemp)
    echo "$USER ALL=(root) NOPASSWD: $bin" > "$tmp"
    if sudo visudo -cf "$tmp" >/dev/null; then
      sudo install -o root -g root -m 440 "$tmp" "$SUDOERS_FILE" && ok "created $SUDOERS_FILE"
    else
      warn "sudoers syntax check failed; rule not installed"
    fi
    rm -f "$tmp"
  else
    warn "Skipped. Without the rule the toggle can't start the hotspot."
  fi
  return 0
}
