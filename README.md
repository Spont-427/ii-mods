# ii-mods

Personal mods for [end-4's illogical-impulse](https://github.com/end-4/dots-hyprland) Hyprland dotfiles (the Quickshell `ii` shell).

Each mod lives in its own folder under `mods/`, and one script installs or removes it for you. Run it again after every update of the end-4 dotfiles to re-apply your mods.

| Mod | What it does |
| --- | --- |
| [`hotspot-toggle`](mods/hotspot-toggle/README.md) | Adds a Wi-Fi hotspot tile to the right sidebar quick toggles (uses `create_ap`) |

> These mods were made and tested against the `ii` Quickshell layout where the toggles live in
> `~/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/` and
> `~/.config/quickshell/ii/modules/common/models/quickToggles/`.
> If end-4 reorganizes things in a future update, a mod may need adjusting.

---

## Table of contents

1. [Before you start](#1-before-you-start)
2. [Quick install (recommended)](#2-quick-install-recommended)
3. [What the installer changes](#3-what-the-installer-changes)
4. [Using the hotspot tile](#4-using-the-hotspot-tile)
5. [Manual install (no script)](#5-manual-install-no-script)
6. [After updating end-4's dotfiles](#6-after-updating-end-4s-dotfiles)
7. [Uninstall](#7-uninstall)
8. [Troubleshooting](#8-troubleshooting)
9. [Adding your own mods](#9-adding-your-own-mods)

---

## 1. Before you start

You need:

- **Arch Linux** (or an Arch-based distro) with **Hyprland** and the **end-4 illogical-impulse dotfiles** already installed and working. The shell folder `~/.config/quickshell/ii` must exist.
- **git** and **python3**: `sudo pacman -S git python`
- For the hotspot mod only:
  - **create_ap**, from the AUR: `yay -S create_ap` (or `paru -S create_ap`)
  - A Wi-Fi card that can run as an access point. Check with `iw list | grep -A10 "valid interface combinations"`. You want to see `AP` listed. To share Wi-Fi *over the same Wi-Fi card* you need `AP` and `managed` in the same combination.

Not sure about something? Everything the installer does is listed in [section 3](#3-what-the-installer-changes), and every changed file is backed up.

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

#    ...or all of them
./install.sh
```

For the hotspot mod the installer will ask you:

1. **Wi-Fi interface**: press Enter to accept the detected one (usually `wlan0`).
2. **Network name** and **password**: what other devices will see and type in. The password must be 8 to 63 characters. It is saved only on your computer in `~/.config/ii-mods/hotspot.conf`, never in the repo.
3. **Add a sudo rule?** Answer `y`. The tile runs `sudo create_ap` in the background, which has no terminal to type a password into. See [the security note](mods/hotspot-toggle/README.md#security-note) before saying yes.

When it finishes, Quickshell normally reloads by itself. If the tile doesn't show up:

```bash
killall qs; qs -c ii & disown
```

### Handy options

| Command | Meaning |
| --- | --- |
| `./install.sh --list` | List available mods |
| `./install.sh NAME` | Install one mod |
| `./install.sh` | Install every mod (asks first) |
| `./install.sh --uninstall NAME` | Remove a mod |
| `./install.sh --yes ...` | Don't ask questions, use defaults (skips the sudo rule) |
| `II_QS_DIR=/path/to/ii ./install.sh ...` | Use a different shell folder |

---

## 3. What the installer changes

Nothing is hidden. For `hotspot-toggle` it does exactly this:

| # | Action | Where |
| --- | --- | --- |
| 1 | Copies `HotspotToggle.qml` (the tile's logic) | `~/.config/quickshell/ii/modules/common/models/quickToggles/` |
| 2 | Copies the helper script `ii-hotspot` | `~/.local/bin/` |
| 3 | Makes `AndroidHotspotToggle.qml` by copying the Cloudflare WARP tile wrapper and renaming it | `~/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/` |
| 4 | Adds a `DelegateChoice` block (between `// ii-mods:hotspot begin/end` comments) so the sidebar knows the new tile type | `.../androidStyle/AndroidToggleDelegateChooser.qml` |
| 5 | Adds a `hotspot` tile to your Android-style layout, right after `cloudflareWarp` | `~/.config/illogical-impulse/config.json` |
| 6 | Creates your hotspot settings (only if missing, permissions `600`) | `~/.config/ii-mods/hotspot.conf` |
| 7 | Optionally adds a sudo rule for `create_ap` (asks first) | `/etc/sudoers.d/ii-mods-create_ap` |

Safety nets:

- Files that get **patched** (the chooser and `config.json`) are copied first to `~/.local/state/ii-mods/snapshots/`.
- Files of yours that get **replaced** are saved to `~/.local/state/ii-mods/backups/` and restored on uninstall.
- Every file the installer creates is recorded in `~/.local/state/ii-mods/manifests/`, so uninstall removes exactly those files and nothing else.
- Running the installer twice is safe; it detects what is already done.
- `config.json` is rewritten with standard 4-space indentation, so a diff may show whitespace changes. The content is otherwise identical.

---

## 4. Using the hotspot tile

1. Open the right sidebar and click the **pencil icon** (edit mode) if the tile isn't already in the grid. Drag it where you want it.
2. Click the **Hotspot** tile to turn the hotspot on. It lights up once it is running, which can take a few seconds.
3. Click it again to turn it off.

Change the name, password or interface any time by editing `~/.config/ii-mods/hotspot.conf`. No reinstall is needed.

---

## 5. Manual install (no script)

If you prefer to do it by hand, or to understand what the script does. From the repo folder:

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

---

## 6. After updating end-4's dotfiles

Updating the dotfiles can overwrite files a mod touched, such as the chooser and `config.json`. Just run the installer again:

```bash
cd ~/ii-mods        # wherever you cloned it
git pull            # get new mods or fixes, if any
./install.sh
```

If the installer complains that a file is missing or has an unexpected layout, end-4 changed something. See [Troubleshooting](#8-troubleshooting).

---

## 7. Uninstall

```bash
./install.sh --uninstall hotspot-toggle
```

This removes the files, the chooser block and the `config.json` entries, and restores anything of yours it replaced. It also offers to delete the sudo rule. Your `~/.config/ii-mods/hotspot.conf` is kept; delete it yourself if you want.

---

## 8. Troubleshooting

**The tile doesn't appear.**
Restart the shell (`killall qs; qs -c ii & disown`) and read its log for the file and line of any error: `qs log -c ii`. Then check that all three pieces exist: `HotspotToggle.qml`, `AndroidHotspotToggle.qml`, and the `hotspot` block in `AndroidToggleDelegateChooser.qml`. Add the tile through edit mode (pencil icon) if it isn't in your layout.

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
`INET_IFACE` in `hotspot.conf` must be the interface that really has internet. If you are on Ethernet, set `INET_IFACE` to your Ethernet interface (see `ip link`).

**My Wi-Fi drops when the hotspot starts.**
Your card can't act as a client and an access point at the same time. Use Ethernet for internet and set `INET_IFACE` accordingly, or use a USB Wi-Fi adapter.

**The installer says a file is missing.**
The end-4 layout changed. Find where `CloudflareWarp` lives now with `grep -rn CloudflareWarp ~/.config/quickshell/ii` and adjust the paths in `lib/helpers.sh` and the mod's `mod.sh`. If you are using a non-default location, use `II_QS_DIR=...`.

**I broke something and want my old files back.**
Everything the installer changed was copied first. Look in `~/.local/state/ii-mods/snapshots/` (patched files) and `~/.local/state/ii-mods/backups/` (replaced files).

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
3. If the mod also edits an existing file (like adding a line to another QML file), **don't copy the whole upstream file**. It breaks when end-4 updates. Instead, write the small edit as a step in `mod.sh`. See `mods/hotspot-toggle/mod.sh` and `lib/helpers.sh` for examples (`patch_delegate_chooser`, `config_toggle`).
4. Test it: `./install.sh my-cool-mod`, then `./install.sh --uninstall my-cool-mod`, then install again.
5. Commit:

```bash
git add mods/my-cool-mod
git commit -m "Add my-cool-mod"
git push
```

Never put passwords, tokens or personal data in a mod. Read them from a file in `~/.config/ii-mods/`, like the hotspot mod does.

---



---

Not affiliated with end-4. Use at your own risk, and keep your own backups.
