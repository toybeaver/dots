# quickshell configs

Quickshell configurations for this machine. Each top-level directory is a
separate config, selected with `quickshell -c <dir>`.

| Config | What it is |
| --- | --- |
| `snek/` | The live sidebar — 45px left bar with workspace dots, battery, clock, date |
| `lock/` | Session lock screen (`ext-session-lock-v1` + PAM) |
| `simple/`, `example/` | Earlier experiments, not in use |

This repo is half of a pair. The compositor config that launches these lives in
**[dots](../dots)** (`~/Source/dots`), and the greetd greeter there is a
deliberate visual duplicate of `lock/` — see [Gotchas](#gotchas).

## Setup

```sh
ln -s ~/Source/quickshell ~/.config/quickshell
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
  printf 'exec "quickshell -p ~/Source/quickshell/lock/shell.qml; swaymsg exit"\n' > /tmp/lk
  WLR_BACKENDS=wayland sway --config /tmp/lk
  ```

- **The sidebar has no compositor blur rule, on purpose.** It reserves an
  exclusive zone over a near-flat wallpaper, so there is nothing behind it to
  blur — and `decoration:blur` post-processing (brightness/contrast/vibrancy)
  applied to it *darkened the pills and made them speckle*. Do not re-add one.
- **The greeter in dots is an intentional duplicate.** It runs as the `greeter`
  user, which cannot read `/home`, so the two cannot share code. A visual change
  here wants the same change there.
