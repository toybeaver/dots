# dots

Config for this machine. Hyprland + Quickshell, dark neon theme built around the
wallpapers.

The Quickshell configs — the sidebar and the lock screen — live in
[`quickshell/`](quickshell/README.md). They were a separate repo until they were
merged in here with their history intact.

## Layout

| Path | |
| --- | --- |
| `.config/hypr/` | Compositor: binds, blur, borders, autostart, `scripts/screenshot.sh` |
| `.config/mako/` | Notifications — dark glass |
| `.config/rofi/` | Launcher — dark glass |
| `etc/greetd/` | Login greeter (Quickshell) + `install.sh` |
| `etc/systemd/logind.conf.d/` | Hands the power key to the compositor |
| `quickshell/` | Quickshell configs — the `snek` sidebar, its control center, and the `lock` screen |
| `.config/{alacritty,ghostty,niri,waybar,fuzzel}/` | Other configs, untouched by the theme work |

`.config/*` is symlinked into place. `etc/*` is **copied** by an install script —
see below for why.

## Setup

### 1. Packages

```sh
sudo pacman -S hyprland quickshell qt6-shadertools \
               mako rofi swaybg \
               greetd greetd-gtkgreet \
               grim slurp wl-clipboard jq libnotify \
               brightnessctl wireplumber noto-fonts
```

`greetd-gtkgreet` is not used but is kept installed as a fallback greeter — see
[Greeter](#3-greeter-root).

### 2. Symlinks

```sh
ln -s ~/Source/dots/.config/hypr  ~/.config/hypr
ln -s ~/Source/dots/.config/mako  ~/.config/mako
ln -s ~/Source/dots/.config/rofi  ~/.config/rofi
ln -s ~/Source/dots/quickshell    ~/.config/quickshell
```

`quickshell -c <name>` resolves `~/.config/quickshell/<name>/shell.qml`, so that
last symlink is what makes `-c snek` and `-c lock` work. Without it the bar and
lock screen do not start.

### 3. Greeter (root)

```sh
sudo ~/Source/dots/etc/greetd/install.sh
```

Optionally with a wallpaper — the greeter runs as the `greeter` user and cannot
read `/home`, so an image has to be copied somewhere world-readable:

```sh
sudo GREETER_BG=~/Pictures/wallpaper/gon.png ~/Source/dots/etc/greetd/install.sh
```

The script **copies** rather than symlinks, for the same permission reason, and
backs up whatever it replaces. **Re-run it after editing anything under
`etc/greetd/`** — the repo is not live.

`/etc/greetd/environments` is deliberately *not* installed. It is the live list
of sessions, maintained by hand; installing it from here would silently revert
additions.

### 4. Power key (root)

```sh
sudo install -Dm644 ~/Source/dots/etc/systemd/logind.conf.d/10-power-key.conf \
                    /etc/systemd/logind.conf.d/10-power-key.conf
sudo systemctl reload systemd-logind
```

Without this the power button shuts the machine down instantly — logind acts
before the compositor ever sees the press.

### 5. Oswald font — manual

**Not available as a package.** Installed by hand at
`/usr/share/fonts/TTF/Oswald/`. The bar, greeter, lock screen, mako titles and
rofi prompt all ask for it by name and silently fall back to a default sans
without it. See [`quickshell/README.md`](quickshell/README.md#oswald-font--manual).

### 6. Wallpapers — not tracked

Images live in `~/Pictures/wallpaper/` and are not in this repo. The autostart
line in `hyprland.lua` references `gon.png` (laptop) and `alucard.png` (external)
by path; point it wherever yours are.

The theme colours are **sampled from `gon.png`** — its neon magenta `#f61cbe`
and cyan `#15fcfd`, scaled down per surface: window borders at 60%, the sidebar
rim at 75% (a 1px hairline needs more punch than a whole window frame). Both are
recorded next to the values that use them. Change the wallpaper and none of it
matches any more.

## Keybinds added

| Key | |
| --- | --- |
| `Super` + `Escape` | Lock |
| Copilot key | Control center — it emits `Shift+Super+F23`, so that chord is taken |
| Lid close | Lock (logind still suspends afterwards) |
| Power button | Press again within 3s to shut down |
| `Print` | Region screenshot → clipboard + `~/Pictures/screenshots` |
| `Shift`+`Print` / `Super`+`Print` | Whole monitor / active window |

The control center — power, volume, wifi and radio toggles — opens from the last
pill in the sidebar or the Copilot key. The key reaches it over the shell's IPC
socket rather than launching anything, since it lives inside the running bar. See
[`quickshell/README.md`](quickshell/README.md#the-control-center).

## Gotchas

- **`hyprctl keyword` does not work here.** The config is Lua, and Hyprland
  rejects `keyword` on non-legacy parsers. Runtime changes go through
  `hyprctl eval` with the `hl.*` API.
- **Blur settings reach every surface with a blur layer rule.** They are not
  cosmetic: `decoration:blur` brightness/contrast/vibrancy tuned for mako and
  rofi once silently darkened the sidebar pills and made them speckle. The
  sidebar has no blur rule now, deliberately — see the note where its rule used
  to be in `hyprland.lua`. mako, rofi and the control center panel do have one.
- **`ignore_alpha` can scope a blur to part of a surface.** The control center
  is one full-screen surface holding both the panel and the dim behind it, so
  blurring it at the usual `0.05` would frost the whole desktop. The dim sits at
  alpha 0.55 and the panel at ~0.91, so a threshold of 0.70 blurs the popup and
  leaves the rest of the screen sharp.
- **More blur looks worse.** At `size 6 / passes 3` the backdrop behind a
  notification homogenises into flat colour, which reads as milky rather than
  glassy. Glass wants shapes softened but still recognisable.
- **For legibility over bright content, reach for `blur:brightness`, not blur
  size.** Blur softens detail but preserves average brightness — a blurred white
  page is still white.
- **Any git operation here can desync the running compositor.** Hyprland watches
  `hyprland.lua` and auto-reloads, but coalesces rapid writes — a branch switch
  or merge can leave the file correct on disk while the running config is stale
  and keybinds have silently vanished. Run `hyprctl reload` afterwards.
- **Do not `systemctl restart greetd` while logged in.** Your session is a child
  of greetd and would be killed. Log out or reboot to see greeter changes.
- **The lock screen is fail-secure.** If it dies while locked the session stays
  locked. Ctrl+Alt+F2, then `loginctl unlock-session`.
