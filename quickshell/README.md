# quickshell configs

Quickshell configurations for this machine. Each top-level directory is a
separate config, selected with `quickshell -c <dir>`.

| Config | What it is |
| --- | --- |
| `snek/` | The live sidebar — 45px left bar with workspace dots, battery, clock, date, and the control center |
| `lock/` | Session lock screen (`ext-session-lock-v1` + PAM) |
| `simple/`, `example/` | Earlier experiments, not in use |

These are launched by the compositor config in [`../.config/hypr/`](../.config/hypr),
and the greetd greeter in [`../etc/greetd/`](../etc/greetd) is a deliberate visual
duplicate of `lock/` — see [Gotchas](#gotchas).

This was its own repository until it was merged into dots, history and all.

## Setup

```sh
ln -s ~/Source/dots/quickshell ~/.config/quickshell
```

`quickshell -c <name>` resolves `~/.config/quickshell/<name>/shell.qml`, so the
symlink is what makes `-c snek` and `-c lock` work.

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

`snek` is started by the compositor — see the autostart block in dots'
`hyprland.lua`. `lock` is launched on demand by keybinds defined there.

## The glass shader

`snek/shaders/glass.frag` draws the sidebar pills. It is a **translucent
overlay** — it emits alpha and lets the compositor composite the real wallpaper
underneath, rather than sampling the wallpaper itself.

Rebuild after editing:

```sh
cd snek/shaders && /usr/lib/qt6/bin/qsb --qt6 -o glass.frag.qsb glass.frag
```

Both files are committed. Editing the `.frag` without recompiling changes
nothing at runtime.

`snek/glass/GlassSurface.qml` wraps it. Its defaults are the sidebar pill's
values, so changing one there retunes every glass surface in the shell at once.

## The control center

The last pill in the bar — the Hunter x Hunter mark — dims the screen and opens a
modal panel. Design notes are in
[`../docs/superpowers/specs/`](../docs/superpowers/specs).

| | |
| --- | --- |
| Layout | A literal 3-row x 5-column `GridLayout`. Four cells are deliberately empty and reserved. |
| Power / restart / log out | Arm-then-confirm with a 3s window, matching the `MOD+SHIFT+Q` bind in `hyprland.lua` |
| Volume | Vertical slider on the default Pipewire sink, clamped to 100% |
| Wifi | SSID plus local IPv4; click toggles the radio |
| Mute / airplane | Toggles; airplane restores Bluetooth only if it was on beforehand |
| Surface | Dark fill at 0.80 plus a compositor blur rule (`snek-control-glass`), scoped to the panel with `ignore_alpha` |
| Wifi list | Chevron on the wifi tile slides to a second page: connected network, refresh, and a scrollable list with inline password entry |

Dismiss with `Escape`, a click outside, or the button again.

It can also be driven from outside the shell, which is how the Copilot key opens
it:

```sh
quickshell -c snek ipc call control toggle   # also: open, close
```

There is no process to launch — the control center lives inside the running bar,
so a keybind has no other way to reach it. It opens on whichever monitor has
focus.

Size is one knob: `factor` in `consts/ControlMetrics.qml`. Every dimension goes
through `px()`, so the panel scales as a unit.

Adding a tile means dropping a component into one of the reserved cells with its
`Layout.row`/`Layout.column` set — see the comment beside them in
`ControlPanel.qml` for why they are placeholders rather than nothing.

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
- **A NEW import directory needs a full restart, not a reload.** Adding
  `components/control/wifi/` and `import "wifi"` made every reload fail with
  `module "wifi" is not installed` while the already-running instance kept
  serving the last good config — so the bar looked fine and silently ignored
  every subsequent edit. Quickshell resolves directory imports when the process
  starts. Kill and relaunch after adding one.
- **Adding a pill shifts the whole bar by more than its height.** `ColumnLayout`
  contributes its default 5px spacing on top of each pill's explicit
  `Layout.bottomMargin`.
