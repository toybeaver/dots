pragma Singleton

import Quickshell
import QtQuick

// Neo-brutalism, light.
//
// Loud, flat, high-contrast: saturated blocks on warm paper, every one outlined
// and shadowed in pure black. No gradient, no blur, no soft corner anywhere in
// the theme.
//
// The hue lives in the BLOCK here. Its dark twin inverts exactly that — see
// neo-brutal-dark/consts/Theme.qml — and the two share every component file
// unchanged, because the swap happens in one line of ControlTile.
//
// This is the one bright theme in the set. If it is too much to look at, that
// is not a bug to tune out with softer colours: use the dark twin, which is
// built for the same look at a tenth of the light output.
Singleton {
  id: root

  readonly property string name: "neo-brutal"
  readonly property string label: "Neo Brutal"

  readonly property string sidebarLayer: root.name + "-sidebar"
  readonly property string controlLayer: root.name + "-control"

  readonly property var colors: ({
    // Warm paper rather than white. Pure white behind pure black borders
    // vibrates, and cream is the colour this style has used since it borrowed
    // it from print.
    "bg": "#f4f1e8",

    // Black. Not near-black — the whole style rests on the border being
    // absolute, and #1a1a1a reads as a design decision where #000 reads as ink.
    "fg": "#000000",
    "edge": "#000000",
    "edge_alt": "#000000",

    "muted": "#57534a",

    "warning": "#ffb800",
    "danger": "#ff4d4d",

    // Default block fill, for anything not given a hue.
    "surface": "#ffffff",

    // The control center slab. Opaque: there is no blur rule for this theme
    // and nothing behind a block ever shows through.
    "panel": "#fff4f1e8",

    // Ink for text and icons sitting ON a coloured block, as opposed to `fg`,
    // which is for text on the panel or the bare desktop. identical to fg/muted here — the light theme's panel and blocks are both pale, so one ink serves both.
    "on_block": "#000000",
    "on_block_dim": "#57534a",

    // "No hue assigned". Means a plain white block here; the twin
    // defines the same NAME as the equivalent for its own inversion, which is
    // what lets ToggleTile and friends stay byte-identical across the two.
    "neutral": "#ffffff",

    // ---- the palette proper -------------------------------------------------
    // Assignment is in MainView and the sidebar components, so recolouring is a
    // matter of swapping names there rather than editing components.
    "acc_yellow": "#ffd93d",
    "acc_pink": "#ff6ba8",
    "acc_cyan": "#4ecdc4",
    "acc_lime": "#b8e62d",
    "acc_orange": "#ff8c42",
    "acc_violet": "#a78bfa"
  })


  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
