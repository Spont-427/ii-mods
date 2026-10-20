# hotspot-toggle

A **Hotspot** tile for the right sidebar quick toggles of end-4's illogical-impulse. Click it to start or stop a Wi-Fi hotspot with [`create_ap`](https://github.com/oblique/create_ap).

## Requirements

- `create_ap` from the AUR: `yay -S create_ap`
- A Wi-Fi card that supports access-point mode (`iw list`)
- The Android-style quick toggles panel (the one with the pencil edit mode)

## Install / uninstall

From the repo root:

```bash
./install.sh hotspot-toggle
./install.sh --uninstall hotspot-toggle
```

See the [main README](../../README.md) for what exactly is changed, and for the manual steps.

## Settings

`~/.config/ii-mods/hotspot.conf` (created by the installer, permissions `600`, never committed):

```bash
WIFI_IFACE="wlan0"   # card that broadcasts the hotspot
INET_IFACE="wlan0"   # interface that has internet
SSID="Hyprland"      # network name
PASSWORD="..."       # 8 to 63 characters
```

This is the same as running `sudo create_ap --daemon WIFI_IFACE INET_IFACE SSID PASSWORD` in a terminal.

## How it works

- `HotspotToggle.qml` is the tile. It calls `~/.local/bin/ii-hotspot start|stop|status` and polls `status` every 3 seconds to stay in sync, even if you start the hotspot from a terminal.
- `ii-hotspot` reads the settings file and runs `sudo -n create_ap ...`. `-n` means "never ask for a password", which is why the sudo rule below is needed.
- `create_ap --daemon` runs the hotspot in the background, so it keeps running if the shell restarts.

## Security note

The installer can create `/etc/sudoers.d/ii-mods-create_ap` containing:

```
YOUR_USER ALL=(root) NOPASSWD: /usr/bin/create_ap
```

This lets any program running as your user start or stop `create_ap` as root without a password. `create_ap` can do a lot as root (it reconfigures network interfaces and firewall rules), so on a shared or untrusted machine think twice. If you prefer, skip the rule and run `sudo create_ap ...` yourself in a terminal; the tile then just won't be able to start it.

## Known limitations

- Written against the `ii` Quickshell layout of end-4's dotfiles in October 2026. If a tile property or file path is renamed upstream, the installer's pre-flight check or the shell log will tell you.
- Many Wi-Fi cards can't be a client and an access point at the same time. If your connection drops when the hotspot starts, use Ethernet for internet.
- The classic-style toggle panel isn't wired up, only the Android style.
