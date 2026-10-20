# shellcheck shell=bash
# lockscreen-music — a small now-playing card on the Quickshell lock screen.
#
# files/  -> LockMusicWidget.qml is copied into modules/ii/lock/
# hook    -> adds one child object to LockSurface.qml (markers: ii-mods:lockscreen-music)

MOD=lockscreen-music
LOCK_SURFACE="$QS_DIR/modules/ii/lock/LockSurface.qml"
SNIPPET_ID=lockscreen-music
POS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/ii-mods/lockscreen-music.conf"

mod_description() {
  echo "Elegant now-playing card on the lock screen, themed with your Material You palette"
}

mod_check() {
  need_file "$LOCK_SURFACE" \
    "the Quickshell lock screen was not found; is this the end-4 'ii' family with modules/ii/lock/?"
  need_file "$QS_DIR/modules/common/Appearance.qml"
  grep -q "m3surfaceContainer" "$QS_DIR/modules/common/Appearance.qml" \
    || warn "Appearance.qml has no m3surfaceContainer; the card's colours may not resolve"
  if [[ -f $II_CONFIG ]] && grep -Eq '"useHyprlock"[[:space:]]*:[[:space:]]*true' "$II_CONFIG"; then
    warn "Your config has lock.useHyprlock = true. This mod only works with the Quickshell lock screen."
    warn "Set it to false in $II_CONFIG (or in Settings) to see the card."
  fi
}

mod_post_install() {
  local pos saved snippet anchors

  # remember the last choice, so re-running (e.g. after a dotfiles update) keeps it
  saved=bottom-left
  if [[ -f $POS_CONF ]]; then
    saved=$(sed -n 's/^POSITION=//p' "$POS_CONF" | head -n1)
    saved=${saved:-bottom-left}
  fi

  pos=${LOCK_MUSIC_POSITION:-}
  if [[ -z $pos ]]; then
    info "Where should the card sit on the lock screen?"
    info "  bottom-left, bottom-right, bottom-center, top-left, top-right, top-center"
    pos=$(prompt_text "Position" "$saved")
  fi

  case $pos in
    bottom-left)   anchors=$'anchors.left: parent.left\nanchors.bottom: parent.bottom\nanchors.leftMargin: 40\nanchors.bottomMargin: 40' ;;
    bottom-right)  anchors=$'anchors.right: parent.right\nanchors.bottom: parent.bottom\nanchors.rightMargin: 40\nanchors.bottomMargin: 40' ;;
    bottom-center) anchors=$'anchors.horizontalCenter: parent.horizontalCenter\nanchors.bottom: parent.bottom\nanchors.bottomMargin: 40' ;;
    top-left)      anchors=$'anchors.left: parent.left\nanchors.top: parent.top\nanchors.leftMargin: 40\nanchors.topMargin: 40' ;;
    top-right)     anchors=$'anchors.right: parent.right\nanchors.top: parent.top\nanchors.rightMargin: 40\nanchors.topMargin: 40' ;;
    top-center)    anchors=$'anchors.horizontalCenter: parent.horizontalCenter\nanchors.top: parent.top\nanchors.topMargin: 40' ;;
    *) warn "Unknown position '$pos', using '$saved'"
       pos=$saved
       case $pos in
         bottom-right)  anchors=$'anchors.right: parent.right\nanchors.bottom: parent.bottom\nanchors.rightMargin: 40\nanchors.bottomMargin: 40' ;;
         bottom-center) anchors=$'anchors.horizontalCenter: parent.horizontalCenter\nanchors.bottom: parent.bottom\nanchors.bottomMargin: 40' ;;
         top-left)      anchors=$'anchors.left: parent.left\nanchors.top: parent.top\nanchors.leftMargin: 40\nanchors.topMargin: 40' ;;
         top-right)     anchors=$'anchors.right: parent.right\nanchors.top: parent.top\nanchors.rightMargin: 40\nanchors.topMargin: 40' ;;
         top-center)    anchors=$'anchors.horizontalCenter: parent.horizontalCenter\nanchors.top: parent.top\nanchors.topMargin: 40' ;;
         *)             pos=bottom-left
                        anchors=$'anchors.left: parent.left\nanchors.bottom: parent.bottom\nanchors.leftMargin: 40\nanchors.bottomMargin: 40' ;;
       esac ;;
  esac

  mkdir -p "$(dirname "$POS_CONF")"
  printf 'POSITION=%s\n' "$pos" > "$POS_CONF"

  snippet=$(mktemp)
  { echo "LockMusicWidget {"; sed 's/^/    /' <<<"$anchors"; echo "}"; } > "$snippet"
  # Always replace the old block, so re-running really applies the new position.
  uninject_qml_child "$LOCK_SURFACE" "$SNIPPET_ID"
  inject_qml_child "$MOD" "$LOCK_SURFACE" "$SNIPPET_ID" "$snippet"
  rm -f "$snippet"

  ok "card position: $pos"
  info "To preview: play something, then run   loginctl lock-session"
  info "To move it again: ./install.sh lockscreen-music   (or LOCK_MUSIC_POSITION=top-right ./install.sh lockscreen-music)"
}

mod_pre_uninstall() {
  uninject_qml_child "$LOCK_SURFACE" "$SNIPPET_ID"
}
