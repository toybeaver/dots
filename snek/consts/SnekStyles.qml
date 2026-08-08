pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

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

    // Glass tokens, in #AARRGGBB. Consumed by shaders/glass.frag — the alpha
    // channel is a strength, not an opacity: the shader multiplies each by a
    // mask it derives from the pill's signed distance field.
    "glass_tint": "#0fffffff",

    // The rim is a magenta-to-cyan gradient, the same pair Hyprland uses for
    // the active window border and sampled from gon.png. Held at 75% of the
    // wallpaper's neon — brighter than the window border's 60% because this is
    // a 1px hairline on a 40px pill rather than a frame around a whole window,
    // so it needs more punch to register at all.
    //
    // A white rim was correct against the old green wallpaper. Against near
    // black it just reads grey, which is what stopped the pills matching the
    // neon theme.
    "glass_edge": "#b8158e",
    "glass_edge_alt": "#0fbdbd"
  })


  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
