# Snek control center — design

A control center for the `snek` Quickshell sidebar: a logo button below the date
widget that dims the screen and opens a modal panel with power actions, volume,
wifi and radio toggles.

Everything here inherits the theme decisions already made — the glass shader, the
magenta/cyan rim sampled from `gon.png`, Oswald for titles and Noto Sans for body
text, and no compositor blur.

## Constraints inherited from the existing setup

- **No blur layer rule.** `decoration:blur` settings reach every surface with a
  blur rule; tuning them for mako and rofi once darkened and speckled the sidebar
  pills. The control center dims the screen itself instead.
- **Colours come from `SnekStyles`.** `get_color()` returns a *string*, so `===`
  against a `color` property is always false. Never compare them.
- **Qt hands colours to shaders premultiplied.** Anything new that feeds the glass
  shader goes through the same un-premultiply path already in `glass.frag`.
- **State collapses the rim.** `SidebarBattery` signals alerts by setting both
  ends of the rim gradient to one colour. Every new state indicator reuses that
  idiom rather than inventing a second visual language.

## Verified platform facts

Probed on this machine, not assumed:

| Fact | Value |
| --- | --- |
| `Networking.devices` / `wifiEnabled` | Populate **asynchronously** after first binding. Must be bound reactively, never read once. |
| `DeviceType` | `None=0, Wifi=1, Wired=2` |
| `NetworkDevice.address` | The **MAC** (`BC:F1:05:92:ED:4D`), not an IP. No IPv4 anywhere in the module. |
| `WifiNetwork.signalStrength` | `0.0`–`1.0` |
| `Networking.wifiEnabled` | Writable (`setWifiEnabled`) |
| `BluetoothAdapter.enabled` | Writable, but `Bluetooth.defaultAdapter` is currently **null** — `bluetooth.service` is inactive, so `org.bluez` is not on the bus |
| `Pipewire.defaultAudioSink` | `.audio.volume` / `.audio.muted`, requires a `PwObjectTracker` |
| Icon font | **None installed.** Icons must be drawn as vector paths. |

## Layout

A literal 3-row × 5-column grid. Coordinates are `[row:col]`.

```
  c1        c2     c3       c4      c5
┌────────┬─────┬────────────────────────┐
│  ⏻     │  ▮  │                        │  r1
│ power  │  ▮  │    📶   MyNetwork      │
├────────┤  ▮  │         192.168.0.15   │
│  ⟳     │  ▮  ├───────┬───────┬────────┤
│restart │  ▮  │       │       │        │  r2   ← reserved
├────────┤  ▮  ├───────┼───────┼────────┤
│  ⤴     │  ▮  │  🔇   │       │   ✈    │  r3
│ logout │  ▮  │ mute  │       │  air   │
└────────┴─────┴───────┴───────┴────────┘
```

| Cell | Tile |
| --- | --- |
| `[1:1]` | Power off |
| `[2:1]` | Restart |
| `[3:1]` | Log out |
| `[1-3:2]` | Volume slider (vertical) |
| `[1:3-5]` | Wifi |
| `[3:3]` | Mute |
| `[3:5]` | Airplane mode |

Cells `[2:3]`, `[2:4]`, `[2:5]` and `[3:4]` are **deliberately empty and
reserved** for tiles added later.

`GridLayout` derives column widths only from non-spanning items, so a column
holding nothing but a spanned tile collapses to zero width. Each empty cell
therefore carries an invisible `Item` placeholder of the standard tile size. This
is load-bearing, not decoration: without the placeholder at `[2:4]`, column 4
collapses and mute/airplane slide together. A placeholder is also exactly where a
future tile drops in.

Columns `[72, 56, 72, 72, 72]`, rows `[72, 72, 72]`, 10px gaps, 18px padding →
panel ≈ **420 × 272**.

## Components

```
snek/
  glass/GlassSurface.qml            extracted from SidebarPill
  state/ControlCenterState.qml      singleton: open + which screen
  watchers/NetworkWatcher.qml       singleton: wifi, IPv4, airplane
  watchers/AudioWatcher.qml         singleton: default sink volume/mute
  icons/hxh.svg                     the logo
  components/
    sidebar/SidebarControl.qml      the logo button
    control/
      ControlCenter.qml             overlay window: dim + panel
      ControlPanel.qml              the 3x5 grid
      ControlTile.qml               shared glass tile: hover, click, rim state
      TileIcon.qml                  vector icons drawn with Shape/PathSvg
      PowerTile.qml                 arm-then-confirm
      VolumeTile.qml                vertical slider
      WifiTile.qml                  icon + SSID + IPv4
      ToggleTile.qml                mute and airplane
```

### `GlassSurface` — refactor

`SidebarPill` currently inlines the `ShaderEffect` with hardcoded parameters. The
control center needs the same shader at a larger radius, so the effect moves into
`glass/GlassSurface.qml` with `radius`/`bevel`/`fresnel`/`spec`/`grain`/`tint`/
`edge`/`edge2` as properties, defaulting to exactly the pill's current values.

`SidebarPill` keeps its public API (`edgeColor`, `edgeColorAlt`, `glass`) and
becomes a thin wrapper. **The sidebar must look pixel-identical afterwards** —
this is a pure extraction.

### `ControlCenterState`

```qml
property bool open
property var screen     // which ShellScreen shows the panel
function toggle(scr)    // same screen closes, different screen moves it
function close()
```

A singleton rather than a property local to the `Variants` delegate, because with
two monitors **every** screen must dim while the panel appears on only one. A
per-screen property would dim one display and leave the other bright.

### `ControlCenter`

One `PanelWindow` per screen:

- `WlrLayershell.layer: Overlay` — above fullscreen windows
- `WlrLayershell.namespace: "snek-control"` — targetable from `hyprland.lua`
- `exclusionMode: Ignore` — must not reserve space
- `keyboardFocus: Exclusive` while open, `None` when closed, so it never swallows
  typing after dismissal
- `visible` stays true while the dim is still fading, otherwise the close
  animation is never seen

Dim: flat black, opacity 0 → 0.40 over 160ms, `Easing.OutCubic`.

Panel: dark base `#0E1118` at ~0.82 with a `GlassSurface` rim over it, radius 16.
Denser than the sidebar pills for the same reason rofi is denser than mako — it is
a large surface carrying text. Enters with opacity 0 → 1 and scale 0.96 → 1.

Dismiss: click the dim, `Escape`, or click the logo button again.

### Tiles

**`ControlTile`** — glass surface, hover raises `fresnel` 0.60 → 0.85 over 120ms,
a `clicked()` signal, and `edgeColor`/`edgeColorAlt` for state.

**`PowerTile`** — arm-then-confirm, mirroring the `Super+Shift+Q` bind in
`hyprland.lua`: first click arms, label swaps to `sure?`, rim collapses to
`danger`, reverts after **3s** (same timeout as the keybind). Commands:

| Tile | Command |
| --- | --- |
| Power off | `systemctl poweroff` |
| Restart | `systemctl reboot` |
| Log out | `command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown \|\| hyprctl dispatch 'hl.dsp.exit()'` |

The logout string is copied verbatim from `hyprland.lua` so both routes out of the
session behave identically.

Arming is per-tile: arming power and then clicking restart disarms power.

**`VolumeTile`** — vertical, spanning all three rows. Fill is the magenta→cyan
gradient, bottom-up. Click or drag to set, scroll to nudge by 5%. Clamped to
`0.0`–`1.0` — no overdrive, deliberately. Percentage in Oswald at the foot. Fill
desaturates while muted.

**`WifiTile`** — icon plus two lines: SSID in Oswald at full contrast, IPv4 beneath
in thin Noto Sans at reduced opacity. Click toggles `Networking.wifiEnabled`.

States:

| Condition | Title | Subtitle |
| --- | --- | --- |
| Connected | SSID | IPv4 address |
| Enabled, not connected | `Not connected` | — |
| Disabled | `Wi-Fi off` | — |
| No hardware | `No adapter` | — |

The IPv4 address is unavailable from the Quickshell API, so it comes from a
`Process` running `ip -4 -o addr show dev <device>`. It re-runs only when the
active network changes, when wifi is toggled, or when the panel opens — never on a
timer while the panel is closed.

**`ToggleTile`** — shared by mute and airplane. Active collapses the rim to cyan
and takes the icon to full white; inactive keeps the normal gradient with the icon
at 65%.

Airplane mode records whether Bluetooth was enabled before engaging and restores
it on disengage. With `defaultAdapter` null it is a no-op on Bluetooth and
airplane mode reduces to "wifi off" — which means toggling the wifi tile also
lights up the airplane tile. That is honest about what the machine can actually
do, and it starts working the moment `bluetooth.service` comes up, because the
adapter is a reactive binding.

### Icons

No icon font is installed, so `TileIcon` draws each icon with `Shape` /
`ShapePath` / `PathSvg`, switching on a `name` property. One file keeps stroke
weight consistent and lets icons take theme colours directly.

The wifi icon takes a `level` derived from `signalStrength` and fades individual
arcs, which a font glyph could not do.

### The logo

`icons/hxh.svg`, hand-drawn: two X strokes with serif caps flanking a central
diamond.

The mark is two-tone by design — black strokes, red diamond. Rendered in flat
white the diamond merges into the strokes and the shape stops reading, so the
diamond is separated by a **hairline negative-space gap**, cut with
`fill-rule="evenodd"`. The silhouette survives in pure white.

Rendered at 22px inside the 40px pill. The button's rim collapses to cyan while
the panel is open, matching the toggle tiles.

## Out of scope

- Network picker — scanning, saved connections and PSK prompts are a feature of
  their own. The reserved cells are where it would go.
- Per-app volume, input devices, media controls, brightness.
- Persisting airplane mode across shell restarts. State is derived from the live
  radios each time.

## Testing

Nested compositor only, never the live session:

```sh
WLR_BACKENDS=wayland sway --config <throwaway>   # runs quickshell -c snek
```

`Networking`, `Pipewire` and `Bluetooth` are D-Bus and socket based, so they
behave identically nested.

Verify visually rather than by eye on a small crop: `grim -g` to capture,
`ffmpeg -vf scale=…:flags=neighbor` to upscale, and single-pixel sampling to check
colours. The logo gets rendered with `rsvg-convert` and inspected before it ships.

Power tiles must **never** be clicked during testing. Their commands are verified
by asserting the string passed to `Process`, not by running it.
