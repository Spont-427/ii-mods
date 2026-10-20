# lockscreen-music

A small, elegant **now-playing card** for the Quickshell lock screen of end-4's illogical-impulse.

- Shows cover art, title, artist, a thin progress line and previous / play-pause / next buttons.
- Works with anything that speaks MPRIS: Spotify, Firefox/Chromium tabs, mpv, VLC, and so on. It prefers the player that is currently playing.
- **Follows your theme.** All colours come from the Material You palette generated from your wallpaper (`Appearance.m3colors`), so it changes with your wallpaper and with light/dark mode. Nothing is hardcoded.
- Fades in when something is playing or paused and fades out when nothing is.

## Requirements

- The Quickshell lock screen, not hyprlock. Check that `lock.useHyprlock` is `false` (`grep -n useHyprlock ~/.config/illogical-impulse/config.json`).
- A current Qt 6 (the card uses `QtQuick.Effects` for rounded cover art), which any up-to-date Arch install has.

## Install / uninstall

```bash
./install.sh lockscreen-music
./install.sh --uninstall lockscreen-music
```

The installer asks where to put the card (bottom-left by default) and remembers your choice. To move it later, just run the installer again and type another position, or skip the question:

```bash
LOCK_MUSIC_POSITION=top-right ./install.sh lockscreen-music
```

Positions: `bottom-left`, `bottom-right`, `bottom-center`, `top-left`, `top-right`, `top-center`. To test, play some music and run:

```bash
loginctl lock-session
```

## What it changes

| Action | Where |
| --- | --- |
| Copies `LockMusicWidget.qml` | `~/.config/quickshell/ii/modules/ii/lock/` |
| Adds a `LockMusicWidget { ... }` block at the end of the root object, between `// ii-mods:lockscreen-music begin/end` comments | `.../modules/ii/lock/LockSurface.qml` |

`LockSurface.qml` is snapshotted first to `~/.local/state/ii-mods/snapshots/lockscreen-music/`.

## Tweaking

Everything visual is at the top of `LockMusicWidget.qml`: card size (`implicitWidth` / `implicitHeight`), corner radius (`radius`), opacity of the glass effect (`0.80` in `Qt.alpha(...)`) and font sizes. To move the card, re-run the installer and pick another position, or edit the `anchors.*` lines in the injected block in `LockSurface.qml`.

## Known limitations

- Written without access to the live shell, using only Quickshell's own Mpris API and the standard Material theme colours. If the card overlaps the clock or password box on your lock screen, pick another position. If the shell logs errors about it, check `qs log -c ii` and open an issue/ask for a fix.
- The card is added to `LockSurface.qml` at the end of the root object. If end-4 restructures that file, re-run the installer after updating the dotfiles.
- Cover art colours are not sampled; the card uses your wallpaper-derived palette instead, so it always matches the rest of the shell.
