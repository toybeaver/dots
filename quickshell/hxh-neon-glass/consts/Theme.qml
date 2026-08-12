pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  // Identity. `name` MUST match this directory's name — it is what the theme
  // switcher hands to bin/shell-theme, and what every Wayland layer namespace
  // below is built from, so hyprland.lua rules can target one theme without
  // catching the others. `label` is the only part the user ever sees.
  readonly property string name: "hxh-neon-glass"
  readonly property string label: "HxH Neon Glass"

  // Layer namespaces, derived so that copying a theme and changing `name` is
  // enough. hyprland.lua matches "^hxh-neon-glass-control$" for the blur.
  readonly property string sidebarLayer: root.name + "-sidebar"
  readonly property string controlLayer: root.name + "-control"
  readonly property string calendarLayer: root.name + "-calendar"
  readonly property string notificationLayer: root.name + "-notifications"

  // Tuned for the gon / alucard wallpapers: both are near-black with the
  // subject centred, so the bar sits on black rather than the old green.
  // Accents pick the one hue the two share — gon's neon magenta and alucard's
  // crimson both sit in the red-rose family, so a neon rose reads correctly
  // against either.
  readonly property var colors: ({
    // Currently unused — nothing reads this token. Kept as the palette's base
    // so it stays meaningful if something needs a solid backdrop later.
    "bg": "#0b0e14",

    "fg": "#edf1f7",
    "warning": "#ffc24b",
    "danger": "#ff4060",

    // Secondary text — the IP under the SSID, a slider's percentage. Same value
    // the lock screen and greeter use for their muted labels.
    "muted": "#8b93a5",

    // Base fill for the control center slab, in #AARRGGBB. Denser than the
    // sidebar pills for the same reason rofi is denser than mako: it is a large
    // surface carrying text rather than a small transient one, and the glass
    // rim alone does not give text enough to sit on.
    //
    // The panel now carries a compositor blur rule — see the
    // hxh-neon-glass-control-glass layer rule in hyprland.lua. Held at 0.80 after
    // comparing against 0.75: the frost is
    // clearly visible at either value, but the extra density keeps a bright
    // window behind the panel from washing it out, which is what made it feel
    // thin before the blur existed.
    //
    // Do not raise this past ~0.9. Above that almost nothing of the backdrop
    // survives and the blur rule becomes decoration with a cost.
    "panel": "#cc0e1118",

    // Glass tokens, in #AARRGGBB. Consumed by shaders/glass.frag — the alpha
    // channel is a strength, not an opacity: the shader multiplies each by a
    // mask it derives from the pill's signed distance field.
    "tint": "#0fffffff",

    // The rim is a magenta-to-cyan gradient, the same pair Hyprland uses for
    // the active window border and sampled from gon.png. Held at 75% of the
    // wallpaper's neon — brighter than the window border's 60% because this is
    // a 1px hairline on a 40px pill rather than a frame around a whole window,
    // so it needs more punch to register at all.
    //
    // A white rim was correct against the old green wallpaper. Against near
    // black it just reads grey, which is what stopped the pills matching the
    // neon theme.
    "edge": "#b8158e",
    "edge_alt": "#0fbdbd"
  })


  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
