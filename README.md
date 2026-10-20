# ii-mods

Personal mods for [end-4's illogical-impulse](https://github.com/end-4/dots-hyprland) Hyprland dotfiles (the Quickshell `ii` shell).

Each mod lives in its own folder under `mods/`, and one script installs or removes it for you. Run it again after every update of the end-4 dotfiles to re-apply your mods.

| Mod | What it does |
| --- | --- |
| [`hotspot-toggle`](mods/hotspot-toggle/README.md) | Adds a Wi-Fi hotspot tile to the right sidebar quick toggles (uses `create_ap`) |
| [`lockscreen-music`](mods/lockscreen-music/README.md) | Adds a small now-playing card (cover art, title, controls) to the lock screen, themed with your Material You palette |

> These mods were made for the `ii` Quickshell layout, where the sidebar toggles live under
> `~/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/` and the lock screen under
> `~/.config/quickshell/ii/modules/ii/lock/`.
> If end-4 reorganizes things in a future update, a mod may need adjusting.

---

## Table of contents

1. [Before you start](#1-before-you-start)
2. [Quick install (recommended)](#2-quick-install-recommended)
3. [What each mod changes](#3-what-each-mod-changes)
4. [Using the mods](#4-using-the-mods)
5. [Manual install (no script)](#5-manual-install-no-script)
6. [After updating end-4's dotfiles](#6-after-updating-end-4s-dotfiles)
7. [Uninstall](#7-uninstall)
8. [Troubleshooting](#8-troubleshooting)
9. [Adding your own mods](#9-adding-your-own-mods)

---

## 1. Before you start

You need:

- **Arch Linux** (or an Arch-based distro) with **Hyprland** and the **end-4 illogical-impulse dotfiles** already installed and working. The folder `~/.config/quickshell/ii` must exist.
- **git** and **python3**: `sudo pacman -S git python`

Extra requirements per mod:

| Mod | Needs |
| --- | --- |
| `hotspot-toggle` | `create_ap` from the AUR (`yay -S create_ap` or `paru -S create_ap`), and a Wi-Fi card that can run as an access point. Check with `iw list \| grep -A10 "valid interface combinations"` and look for `AP`. To share Wi-Fi over the same card you need `AP` and `managed` in one combination. |
| `lockscreen-music` | The **Quickshell lock screen**, not hyprlock. Check with `grep -n useHyprlock ~/.config/illogical-impulse/config.json`; it should say `false`. A current Qt 6 (any up-to-date Arch install). |

Not sure about something? Everything the installer does is listed in [section 3](#3-what-each-mod-changes), and every changed file is backed up.

---

## 2. Quick install (recommended)

Open a terminal and run these one at a time:

```bash
# 1. Download this repo
git clone https://github.com/Spont-427/ii-mods.git
cd ii-mods

# 2. See which mods are available
./install.sh --list

# 3. Install one mod...
./install.sh hotspot-toggle
./install.sh lockscreen-music

#    ...or all of them
./install.sh
```

The installer asks a few questions, and you can just press Enter to accept the default shown in brackets:

- **hotspot-toggle**
  1. *Wi-Fi interface*: the detected one, usually `wlan0`.
  2. *Network name* and *password*: what other devices see and type in (8 to 63 characters). The password is saved only on your computer in `~/.config/ii-mods/hotspot.conf`, never in the repo.
  3. *Add a sudo rule?* Answer `y`. The tile runs `sudo create_ap` in the background, which has no terminal to type a password into. Read [the security note](mods/hotspot-toggle/README.md#security-note) first.
- **lockscreen-music**
  1. *Position*: where the card sits on the lock screen. One of `bottom-left` (default), `bottom-right`, `bottom-center`, `top-left`, `top-right`, `top-center`. Your choice is remembered.

When it finishes, Quickshell normally reloads by itself. If you don't see the change:

```bash
killall qs; qs -c ii & disown
```

### Handy options

| Command | Meaning |
| --- | --- |
| `./install.sh --list` | List available mods |
| `./install.sh NAME` | Install one mod (running it again re-applies it) |
| `./install.sh` | Install every mod (asks first) |
| `./install.sh --uninstall NAME` | Remove a mod |
| `./install.sh --yes ...` | Never ask questions, use defaults and saved choices (skips the sudo rule) |
| `LOCK_MUSIC_POSITION=top-right ./install.sh lockscreen-music` | Pick the lock-screen card position without being asked |
| `II_QS_DIR=/path/to/ii ./install.sh ...` | Use a different shell folder |

---

## 3. What each mod changes

Nothing is hidden. This is exactly what each mod touches.

### hotspot-toggle

| # | Action | Where |
| --- | --- | --- |
| 1 | Copies `HotspotToggle.qml` (the tile's logic) | `~/.config/quickshell/ii/modules/common/models/quickToggles/` |
| 2 | Copies the helper script `ii-hotspot` | `~/.local/bin/` |
| 3 | Makes `AndroidHotspotToggle.qml` by copying the Cloudflare WARP tile wrapper and renaming it | `~/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/` |
| 4 | Adds a `DelegateChoice` block (between `// ii-mods:hotspot begin/end` comments) so the sidebar knows the new tile type | `.../androidStyle/AndroidToggleDelegateChooser.qml` |
| 5 | Adds a `hotspot` tile to your Android-style layout, right after `cloudflareWarp` | `~/.config/illogical-impulse/config.json` |
| 6 | Creates your hotspot settings (only if missing, permissions `600`) | `~/.config/ii-mods/hotspot.conf` |
| 7 | Optionally adds a sudo rule for `create_ap` (asks first) | `/etc/sudoers.d/ii-mods-create_ap` |

### lockscreen-music

| # | Action | Where |
| --- | --- | --- |
| 1 | Copies `LockMusicWidget.qml` (the card) | `~/.config/quickshell/ii/modules/ii/lock/` |
| 2 | Adds a `LockMusicWidget { ... }` block at the end of the root object, between `// ii-mods:lockscreen-music begin/end` comments, with anchors for your chosen position | `.../modules/ii/lock/LockSurface.qml` |
| 3 | Remembers your position choice | `~/.config/ii-mods/lockscreen-music.conf` |

The card reads whatever media player is active through MPRIS (Spotify, browser tabs, mpv, VLC, ...), takes all its colours from your wallpaper-generated Material You palette (`Appearance.m3colors`), and hides itself when nothing is playing.

### Safety nets (all mods)

- Files that get **patched** (the chooser, `LockSurface.qml`, `config.json`) are copied first to `~/.local/state/ii-mods/snapshots/`.
- Files of yours that get **replaced** are saved to `~/.local/state/ii-mods/backups/` and restored on uninstall.
- Every file the installer creates is recorded in `~/.local/state/ii-mods/manifests/`, so uninstall removes exactly those files and nothing else.
- Running the installer twice is safe. Patched blocks are replaced, not duplicated.
- `config.json` is rewritten with standard 4-space indentation, so a diff may show whitespace changes. The content is otherwise identical.

---

## 4. Using the mods

### Hotspot tile

1. Open the right sidebar and click the **pencil icon** (edit mode) if the tile isn't already in the grid. Drag it where you want it.
2. Click the **Hotspot** tile to turn the hotspot on. It lights up once it is running, which can take a few seconds.
3. Click it again to turn it off.

Change the name, password or interface any time by editing `~/.config/ii-mods/hotspot.conf`. No reinstall is needed.

### Lock-screen music card

1. Play something in any player.
2. Lock the screen: `loginctl lock-session`.
3. The card shows cover art, title, artist, a progress line and previous / play-pause / next buttons. Click the buttons with the mouse. Keyboard input still goes to the password box.

To **move the card**, run the installer again and type another position (or use `LOCK_MUSIC_POSITION=...` as shown in [section 2](#handy-options)). Appearance tweaks (size, corner radius, glass opacity, font sizes) are at the top of `LockMusicWidget.qml`.

> **Tip:** before your first test, know how to recover. If something goes wrong on the lock screen, switch to a text console with `Ctrl+Alt+F3`, log in, and run `cd ~/ii-mods && ./install.sh --uninstall lockscreen-music`. Quickshell reloads edited files on its own, so the lock screen normally recovers after that.

---

## 5. Manual install (no script)

If you prefer to do it by hand, or want to understand what the script does. Run everything from the repo folder.

### hotspot-toggle

**Step 1: copy the files**

```bash
QS=~/.config/quickshell/ii

cp mods/hotspot-toggle/files/modules/common/models/quickToggles/HotspotToggle.qml \
   $QS/modules/common/models/quickToggles/

mkdir -p ~/.local/bin
cp mods/hotspot-toggle/bin/ii-hotspot ~/.local/bin/
chmod +x ~/.local/bin/ii-hotspot
```

**Step 2: make the Android-style wrapper**

```bash
cd $QS/modules/ii/sidebarRight/quickToggles/androidStyle
sed 's/CloudflareWarpToggle/HotspotToggle/g; s/CloudflareWarp/Hotspot/g; s/Cloudflare WARP/Hotspot/g' \
    AndroidCloudflareWarpToggle.qml > AndroidHotspotToggle.qml
```

**Step 3: register the tile type.** Open `AndroidToggleDelegateChooser.qml`, find the block that starts with `DelegateChoice { roleValue: "cloudflareWarp"; ...`, copy the whole block just below itself, and change `"cloudflareWarp"` to `"hotspot"` and `AndroidCloudflareWarpToggle` to `AndroidHotspotToggle`.

**Step 4: add the tile to your layout.** Easiest: open the sidebar, click the pencil icon and add it. Or edit `~/.config/illogical-impulse/config.json`: find the object with `"type": "cloudflareWarp"` and add a copy of it next to it with `"type": "hotspot"` (mind the commas). Check the file is still valid JSON:

```bash
python -m json.tool ~/.config/illogical-impulse/config.json > /dev/null && echo OK
```

**Step 5: your settings**

```bash
mkdir -p ~/.config/ii-mods
cp mods/hotspot-toggle/hotspot.conf.example ~/.config/ii-mods/hotspot.conf
chmod 600 ~/.config/ii-mods/hotspot.conf
nano ~/.config/ii-mods/hotspot.conf      # set SSID and PASSWORD
```

**Step 6: the sudo rule**

```bash
which create_ap          # note the path, usually /usr/bin/create_ap
echo "$USER ALL=(root) NOPASSWD: /usr/bin/create_ap" | sudo tee /etc/sudoers.d/ii-mods-create_ap
sudo chmod 440 /etc/sudoers.d/ii-mods-create_ap
sudo visudo -c           # must say "parsed OK"
```

**Step 7: reload**

```bash
killall qs; qs -c ii & disown
```

### lockscreen-music

**Step 1: copy the card**

```bash
cp mods/lockscreen-music/files/modules/ii/lock/LockMusicWidget.qml \
   ~/.config/quickshell/ii/modules/ii/lock/
```

**Step 2: place it on the lock screen.** Open `~/.config/quickshell/ii/modules/ii/lock/LockSurface.qml` and, just before the very last `}` of the file (the one that closes the root object), add:

```qml
    LockMusicWidget {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 40
        anchors.bottomMargin: 40
    }
```

That puts it at the bottom-left. For another corner, swap `left`/`right` and `bottom`/`top` in the anchors. For the middle, use `anchors.horizontalCenter: parent.horizontalCenter` and drop the left/right lines.

**Step 3: reload and test**

```bash
killall qs; qs -c ii & disown
loginctl lock-session
```

---

## 6. After updating end-4's dotfiles

Updating the dotfiles can overwrite files a mod touched, such as the chooser, `LockSurface.qml` and `config.json`. Just run the installer again. It keeps your saved choices (lock-screen position, hotspot settings):

```bash
cd ~/ii-mods        # wherever you cloned it
git pull            # get new mods or fixes, if any
./install.sh --yes  # re-apply everything without questions
```

If the installer complains that a file is missing or has an unexpected layout, end-4 changed something. See [Troubleshooting](#8-troubleshooting).

---

## 7. Uninstall

```bash
./install.sh --uninstall hotspot-toggle
./install.sh --uninstall lockscreen-music
```

This removes the files and the patched blocks, and restores anything of yours it replaced. The hotspot mod also offers to delete the sudo rule. Your settings files in `~/.config/ii-mods/` are kept; delete them yourself if you want.

---

## 8. Troubleshooting

### General

**The installer says a file is missing.**
The end-4 layout changed. Find where the thing lives now, for example `grep -rn CloudflareWarp ~/.config/quickshell/ii` or `ls ~/.config/quickshell/ii/modules/ii/lock`, and adjust the paths in `lib/helpers.sh` and the mod's `mod.sh`. If your shell folder is somewhere else, use `II_QS_DIR=...`.

**Something is broken and I want my old files back.**
Everything the installer changed was copied first. Look in `~/.local/state/ii-mods/snapshots/` (patched files) and `~/.local/state/ii-mods/backups/` (replaced files), or just uninstall the mod.

**Quickshell shows errors.**
Read its log for the file and line: `qs log -c ii`.

### hotspot-toggle

**The tile doesn't appear.**
Restart the shell (`killall qs; qs -c ii & disown`) and check the log. Then verify all three pieces exist: `HotspotToggle.qml`, `AndroidHotspotToggle.qml`, and the `hotspot` block in `AndroidToggleDelegateChooser.qml`. Add the tile through edit mode (pencil icon) if it isn't in your layout.

**The tile appears but nothing happens when I click it.**
Run the helper in a terminal to see the real error:

```bash
~/.local/bin/ii-hotspot start
```

- "Set a password" means `PASSWORD` in `~/.config/ii-mods/hotspot.conf` is empty or shorter than 8 characters.
- "Could not start" usually means `create_ap` isn't installed or the sudo rule is missing. Test the rule with `sudo -n create_ap --help`: it must run without asking for a password.

**It starts, but the tile never lights up or can't be turned off.**
Check the status the tile polls: `~/.local/bin/ii-hotspot status; echo $?` (0 = running). To stop by hand: `sudo create_ap --list-running`, then `sudo create_ap --stop wlan0`.

**My phone sees the network but has no internet.**
`INET_IFACE` in `hotspot.conf` must be the interface that really has internet. If you are on Ethernet, set it to your Ethernet interface (see `ip link`).

**My Wi-Fi drops when the hotspot starts.**
Your card can't be a client and an access point at the same time. Use Ethernet for internet and set `INET_IFACE` accordingly, or use a USB Wi-Fi adapter.

### lockscreen-music

**The card doesn't show up.**
- Is anything playing or paused? The card hides itself when no player reports a track. Check with `playerctl metadata` (install `playerctl` if needed).
- Are you using hyprlock? The card only exists on the Quickshell lock screen: `grep -n useHyprlock ~/.config/illogical-impulse/config.json` must say `false`.
- Is the block in place? `grep -n "ii-mods:lockscreen-music" ~/.config/quickshell/ii/modules/ii/lock/LockSurface.qml` should show a begin and an end line.
- Check `qs log -c ii` for lines mentioning `LockMusicWidget`.

**The position doesn't change when I re-run the installer.**
Make sure you have the current version of the repo (`git pull`, or copy the latest `mods/lockscreen-music/mod.sh`). Older versions skipped the patch when they saw it was already applied. As a workaround, uninstall and install again.

**The card overlaps the clock or the password box.**
Pick another position, for example `LOCK_MUSIC_POSITION=top-right ./install.sh lockscreen-music`.

**No cover art or the progress bar doesn't move.**
Some players don't publish cover art or their playback position over MPRIS. The card then shows a music-note placeholder or an empty progress line.

---

## 9. Adding your own mods

Every new tweak you make becomes a new folder under `mods/`.

```bash
./scripts/new-mod.sh my-cool-mod
```

This creates:

```
mods/my-cool-mod/
├── mod.sh        ← steps to run (description, checks, patches)
├── README.md     ← explain it for future you
├── files/        ← copied into ~/.config/quickshell/ii (same folder structure)
└── bin/          ← copied into ~/.local/bin
```

Workflow:

1. Make the change in your live config and get it working.
2. Copy the new or changed files into `mods/my-cool-mod/files/`, keeping the same path structure as under `~/.config/quickshell/ii/`. For example `files/modules/ii/bar/MyWidget.qml`.
3. If the mod also edits an existing file (like adding a line to another QML file), **don't copy the whole upstream file**. It breaks when end-4 updates. Instead, write the small edit as a step in `mod.sh`. See `mods/lockscreen-music/mod.sh` (adds a child to a QML file) and `mods/hotspot-toggle/mod.sh` (registers a toggle), with the helper functions in `lib/helpers.sh`.
4. Test it: `./install.sh my-cool-mod`, then `./install.sh --uninstall my-cool-mod`, then install again.
5. Commit:

```bash
git add mods/my-cool-mod
git commit -m "Add my-cool-mod"
git push
```

Never put passwords, tokens or personal data in a mod. Read them from a file in `~/.config/ii-mods/`, like the hotspot mod does.

---

Not affiliated with end-4. Use at your own risk, and keep your own backups.
