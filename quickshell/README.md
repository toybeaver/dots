# quickshell configs

Quickshell configurations for this machine. Each top-level directory is a
separate config, selected with `quickshell -c <dir>`.

| Config | What it is |
| --- | --- |
| `hxh-neon-glass/` | **Theme.** The default look — glass pills over a neon magenta/cyan rim |
| `temp/` | **Theme.** Flat white on black, square, no shader and no blur |
| `shared/` | Not a config. The non-visual half — watchers and state, symlinked into every theme |
| `bin/` | Not a config. `shell-theme`, the launcher and switcher |
| `lock/` | Session lock screen (`ext-session-lock-v1` + PAM) |
| `simple/`, `example/` | Earlier experiments, not in use |

A **theme** is a whole desktop, not a palette: the shell, the wallpaper, mako,
rofi and Hyprland's borders and blur all change together. Switching replaces the
running process — see [Themes](#themes).

These are launched by the compositor config in [`../.config/hypr/`](../.config/hypr),
and the greetd greeter in [`../etc/greetd/`](../etc/greetd) is a deliberate visual
duplicate of `lock/` — see [Gotchas](#gotchas).

This was its own repository until it was merged into dots, history and all.

## Themes

`bin/shell-theme` owns the theme list and the selection. Nothing else names a
theme — not the autostart line, not the keybind, not the QML.

```sh
bin/shell-theme start          # bring the whole desktop up (this is the autostart)
bin/shell-theme next | prev    # step through the list and switch into it
bin/shell-theme set temp
bin/shell-theme apply          # re-apply the current theme without restarting the shell
bin/shell-theme current
bin/shell-theme ipc call theme next      # also: control toggle
```

`apply` is the one to reach for after editing a theme's `desktop/` files — it
repoints the links and reloads mako, rofi, swaybg and Hyprland without touching
the shell.

The selection lives in `~/.local/state/dots/theme` and every switch is appended
to `~/.local/state/dots/shell-theme.log`. In the shell itself the switcher is
the `< name >` tile in the control center, directly under wifi.

### The desktop beyond the shell

A theme also carries the look of everything around the shell, under
`<theme>/desktop/`:

| File | Applied by |
| --- | --- |
| `hypr.lua` | Returns a table of borders, rounding, blur and shadows. `hyprland.lua` `dofile`s it at parse time; a switch runs `hyprctl reload` |
| `mako.conf` | mako runs with `--config` pointed at the active link; reloaded in place with `makoctl reload` |
| `rofi.rasi` | `@theme`-imported by `.config/rofi/config.rasi`, which keeps the behaviour-only `configuration` block |
| `wallpaper` | `<output> <file>` lines; swaybg is restarted, since it has no reload |

`bin/shell-theme` points `~/.local/state/dots/active/{hypr.lua,mako.conf,rofi.rasi}`
at the current theme and drives all four. **Nothing outside that script names a
theme** — not the autostart line, not the keybinds, not rofi's config.

Because all three programs change appearance per theme, the script starts them
too: Hyprland's autostart is a single `shell-theme start`. Login and switching
therefore run the same code and cannot drift apart.

Hyprland's share is deliberately limited to *material* — borders, corners, blur,
shadows. Layout (gaps, tiling, animations) is the same whichever theme is on and
stays in `hyprland.lua`. Every key in `hypr.lua` must be present: it is read
directly rather than merged over defaults.

### What a theme owns, and what it does not

Themes share behaviour and duplicate appearance. `shared/` holds the watchers
(network, battery, time, audio) and the control center's open/page state; each
theme symlinks it in as `shared/` and imports `"../shared/watchers"`.

Everything visual is copied, not shared. That is deliberate: claymorphism and
neo-brutalism differ in component *structure*, not just colour, so a single
parameterised component set would have to be torn out the moment the second
real theme arrived. The cost is that a visual fix has to be applied per theme;
the benefit is that a theme can change anything.

The seam between the two is one file per theme:

| | |
| --- | --- |
| `consts/Theme.qml` | Identity (`name`, `label`), layer namespaces, and the palette |
| `glass/GlassSurface.qml` (hxh-neon-glass) | The material. A shader. |
| `surface/Surface.qml` (temp) | The same API, drawn as a flat rectangle |

`Theme.name` **must** match the directory name — the switcher passes it to
`shell-theme`, and the Wayland layer namespaces are built from it so
`hyprland.lua` can target one theme's surfaces without catching the others.

### Adding one

1. `cp -a hxh-neon-glass mytheme` (`cp -a`, so `shared` stays a symlink).
2. Edit `consts/Theme.qml`: set `name` to `mytheme`, pick a `label`, retune the
   palette.
3. Retune `desktop/`: `hypr.lua`, `mako.conf`, `rofi.rasi` and `wallpaper`.
4. Add `mytheme` to `THEMES` in `bin/shell-theme`.
5. If it wants a compositor blur, copy the `hxh-neon-glass-control-glass` layer
   rule in `hyprland.lua` and match `^mytheme-control$`.

Cold-start it before switching into it — `quickshell -c mytheme` in a nested
compositor. See the note in [Gotchas](#gotchas) about why a broken theme is
worse than an ugly one.

## Setup

```sh
ln -s ~/Source/dots/quickshell ~/.config/quickshell
```

`quickshell -c <name>` resolves `~/.config/quickshell/<name>/shell.qml`, so the
symlink is what makes `-c hxh-neon-glass` and `-c lock` work. It is also what lets
`bin/shell-theme` be found at a stable path from `hyprland.lua`.

### Packages

```sh
sudo pacman -S quickshell qt6-shadertools noto-fonts
```

`qt6-shadertools` is only needed to rebuild the glass shader — the compiled
`.qsb` is committed, so a plain checkout runs without it.

### Oswald font — manual

**Oswald is not in a package.** It is installed by hand at
`/usr/share/fonts/TTF/Oswald/`, and everything here (sidebar numerals, clock,
buttons) asks for it by name. Without it Qt silently falls back to a default
sans and the whole thing looks wrong but does not error.

Download [Oswald](https://fonts.google.com/specimen/Oswald), then:

```sh
sudo mkdir -p /usr/share/fonts/TTF/Oswald
sudo cp -r Oswald /usr/share/fonts/TTF/Oswald/
fc-cache -f
fc-list : family | grep -i oswald   # verify
```

### Running

The compositor autostarts `bin/shell-theme start`, which launches whichever
theme is saved — see the autostart block in dots' `hyprland.lua`. `lock` is
launched on demand by keybinds defined there.

## The glass shader

`hxh-neon-glass/shaders/glass.frag` draws that theme's sidebar pills. It is a **translucent
overlay** — it emits alpha and lets the compositor composite the real wallpaper
underneath, rather than sampling the wallpaper itself.

Rebuild after editing:

```sh
cd hxh-neon-glass/shaders && /usr/lib/qt6/bin/qsb --qt6 -o glass.frag.qsb glass.frag
```

Both files are committed. Editing the `.frag` without recompiling changes
nothing at runtime.

`hxh-neon-glass/glass/GlassSurface.qml` wraps it. Its defaults are the sidebar
pill's values, so changing one there retunes every glass surface in that theme
at once. `temp/surface/Surface.qml` is the flat theme's stand-in for it and
declares the same properties, so components copy between themes unchanged.

## The control center

The last pill in the bar — the Hunter x Hunter mark — dims the screen and opens a
modal panel.

| | |
| --- | --- |
| Layout | A literal 3-row x 5-column `GridLayout`. One cell is deliberately empty and reserved. |
| Power / restart / log out | Arm-then-confirm with a 3s window, matching the `MOD+SHIFT+Q` bind in `hyprland.lua` |
| Volume | Vertical slider on the default Pipewire sink, clamped to 100% |
| Wifi | SSID plus local IPv4; click toggles the radio |
| Mute / airplane | Toggles; airplane restores Bluetooth only if it was on beforehand |
| Surface | hxh-neon-glass: dark fill at 0.80 plus a blur rule (`hxh-neon-glass-control-glass`) scoped to the panel with `ignore_alpha`. temp: opaque, no blur |
| Wifi list | Chevron on the wifi tile slides to a second page: connected network, refresh, and a scrollable list with inline password entry |
| Theme | `< name >` under wifi. The arrows call `bin/shell-theme`, which replaces the whole process |

Dismiss with `Escape`, a click outside, or the button again.

It can also be driven from outside the shell, which is how the Copilot key opens
it:

```sh
quickshell/bin/shell-theme ipc call control toggle   # also: open, close
```

There is no process to launch — the control center lives inside the running bar,
so a keybind has no other way to reach it. It opens on whichever monitor has
focus.

Size is one knob: `factor` in `consts/ControlMetrics.qml`. Every dimension goes
through `px()`, so the panel scales as a unit.

Adding a tile means dropping a component into the reserved cell with its
`Layout.row`/`Layout.column` set — see the comment beside it in `MainView.qml`
for why it is a placeholder rather than nothing.

## Gotchas

Things that cost real debugging time. All are also commented at the relevant
line — this is the index.

- **The shader must not sample the wallpaper.** An earlier version loaded the
  wallpaper as a texture. Qt's JPEG decode does not match what swaybg renders
  (measured: source `90,132,84` vs screen `62,133,80`), so every pill painted a
  subtly wrong copy of the background and looked lighter than its surroundings
  no matter how the tint was set.
- **Qt hands colours to shaders premultiplied.** `edge.rgb * edge.a` squares the
  alpha, and a white tint arrives as grey. Un-premultiply before use.
- **`get_color()` returns a string, not a `color`.** Comparing it against a
  `color` property with `===` is always false. This silently collapsed the rim
  gradient to a single colour.
- **`locked: true` on a `WlSessionLock` is a binding.** It re-asserts `true` the
  instant `unlock()` changes it, so the unlock silently does nothing. Combined
  with quitting immediately afterwards this froze the machine hard — the client
  died while the compositor still considered the session locked. `lock/shell.qml`
  drives `locked` from a mutable property and never quits until
  `lockStateChanged` reports `locked == false`.
- **The lock screen is fail-secure.** If it dies while locked, the session stays
  locked. Recover from a TTY (Ctrl+Alt+F2) with `loginctl unlock-session`, or
  `hyprctl dispatch clear_crashed_lockscreen` if the client actually crashed.
- **Test the lock nested, never in your session.** Running `lock/shell.qml`
  directly locks your real screen:

  ```sh
  printf 'exec "quickshell -p ~/Source/dots/quickshell/lock/shell.qml; swaymsg exit"\n' > /tmp/lk
  WLR_BACKENDS=wayland sway --config /tmp/lk
  ```

- **The sidebar has no compositor blur rule, on purpose.** It reserves an
  exclusive zone over a near-flat wallpaper, so there is nothing behind it to
  blur — and `decoration:blur` post-processing (brightness/contrast/vibrancy)
  applied to it *darkened the pills and made them speckle*. Do not re-add one.
- **The greeter in dots is an intentional duplicate.** It runs as the `greeter`
  user, which cannot read `/home`, so the two cannot share code. A visual change
  here wants the same change there.
- **The frost grain is seeded from `gl_FragCoord`, i.e. screen space.** Move a
  surface and its noise pattern changes. This makes naive pixel-diffing useless
  for "did my refactor change the rendering?" — a surface that shifted position
  reads as different even when the code is identical. Diffing the
  `GlassSurface` extraction showed a max channel delta of 7/255 purely from
  this, against 234 for a genuine one-pixel misalignment.
- **`Quickshell.Networking` populates asynchronously.** For the first moment
  after startup `wifiEnabled` is false and `devices` is empty *on a connected
  machine*. Bind to it; anything that reads it once in a handler gets the
  pre-dbus defaults. The same is true of `Pipewire.defaultAudioSink`, which also
  needs a `PwObjectTracker` before `audio` is non-null.
- **`NetworkDevice.address` is the MAC, not an IP.** The module exposes no IPv4
  anywhere, which is why `NetworkWatcher` shells out to `ip -4 -o addr show`.
- **`ShapePath` is not an `Item`** — it has no `opacity`. Fading one path of an
  icon has to go through the stroke or fill colour's alpha channel.
- **Never hold Quickshell network objects across model changes.** The wifi list
  originally cached the `WifiNetwork` objects to freeze their order. Access
  points come and go constantly while scanning, so that array filled with
  pointers to objects NetworkManager had already torn down, and the shell
  segfaulted roughly once a minute with the wifi page open — every crash report
  ending in `Access point removed` followed by a fault in a destructor. Freeze
  the SSID *order* instead and rebuild the list from the live model each time.
- **A theme that fails to start strands you.** The switcher lives inside the
  shell, so if the theme you switch *into* never comes up there is no bar, no
  control center and no keybind left to switch back with — the desktop is
  simply empty. `bin/shell-theme` therefore verifies the new instance appeared
  and rolls back to the previous theme if it did not, logging both to
  `~/.local/state/dots/shell-theme.log`. Cold-start a new theme nested before
  putting it in `THEMES`.
- **Quickshell survives a broken config; it does not exit.** A cold start with
  a QML error logs `Failed to load configuration` and keeps running with no
  surfaces — so "the bar is gone" and "the process is gone" are different
  faults with the same appearance. Check `quickshell list --all` before
  assuming a crash.
- **`quickshell kill -c <name>` resolves the config directory first**, so it
  cannot kill an instance whose directory was renamed or deleted while it ran.
  That is exactly the situation during a rename. Kill by `--pid`, read out of
  `quickshell list --all`, which is what `shell-theme` does.
- **`shared/` is a symlink into each theme, and both imports and hot-reload
  follow it.** Verified, not assumed: editing `shared/watchers/*` triggers a
  reload in a theme that imports it through the link. The flip side is that one
  edit changes every theme at once — which is the point for a watcher, and
  would be a trap for anything visual. Keep `shared/` non-visual.
- **A NEW import directory needs a full restart, not a reload.** Adding
  `components/control/wifi/` and `import "wifi"` made every reload fail with
  `module "wifi" is not installed` while the already-running instance kept
  serving the last good config — so the bar looked fine and silently ignored
  every subsequent edit. Quickshell resolves directory imports when the process
  starts. Kill and relaunch after adding one.
- **Adding a pill shifts the whole bar by more than its height.** `ColumnLayout`
  contributes its default 5px spacing on top of each pill's explicit
  `Layout.bottomMargin`.
