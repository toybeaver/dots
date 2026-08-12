pragma Singleton

import Quickshell
import QtQuick

// Neo-brutalism, dark.
//
// The same style as its light twin, inverted at exactly one point: the hue
// moves from the BLOCK to the BORDER AND SHADOW. Blocks go near-black, and each
// one is outlined and shadowed in its own saturated colour.
//
// That inversion is forced, not stylistic. The light theme's whole structure is
// black ink on colour; on a dark ground a black border and a black offset
// shadow are both invisible, and the style collapses into flat coloured
// rectangles. Moving the hue to the outline keeps the drawing and drops the
// background out instead.
//
// It also happens to be the kinder of the two to look at. The bright is
// confined to 3px lines and a 5px shadow rather than covering whole surfaces,
// so the screen carries the same colours at a fraction of the light output.
Singleton {
  id: root

  readonly property string name: "neo-brutal-dark"
  readonly property string label: "Neo Brutal Dark"

  readonly property string sidebarLayer: root.name + "-sidebar"
  readonly property string controlLayer: root.name + "-control"

  readonly property var colors: ({
    "bg": "#0c0c0c",

    // Off-white, not #ffffff. The light theme can afford absolute black on
    // paper; absolute white on near-black is the harshest thing a dark theme
    // can do, and this one already carries six saturated hues.
    "fg": "#f2ede3",
    "muted": "#8c877d",

    // Ink. Near-black, the same role black plays in the light twin: the hard
    // outline drawn around a coloured block. It reads as a cut rather than a
    // line, which is what keeps a bright block from bleeding into the desktop.
    "edge": "#08080a",
    "edge_alt": "#08080a",

    "warning": "#ffb800",
    "danger": "#ff5c5c",

    // Default block fill, for anything not given a hue. Same value as
    // `neutral`, so a component that forgets to set an accent still lands on a
    // block its ink can be read against.
    "surface": "#c9c5bc",

    "panel": "#f00d0d10",

    // Ink for text and icons sitting ON a coloured block, as opposed to `fg`,
    // which is for text on the panel or the bare desktop. the dark twin's blocks are bright and its panel is not, so block text and panel text need opposite inks.
    "on_block": "#0c0c0c",
    "on_block_dim": "#3d3a34",

    // "No hue assigned" — a plain PALE block, the same role white plays in the
    // light twin, and pale for the same reason: every block in this theme
    // carries near-black ink, so a dark "neutral" leaves its text at 2.9:1 and
    // effectively unreadable. Measured before it shipped; the workspace dots
    // and the inactive toggles were the visible casualties.
    //
    // Warm grey rather than white — a handful of white blocks on a black
    // desktop is a lamp, and this theme exists to avoid one.
    "neutral": "#c9c5bc",

    // ---- the palette proper -------------------------------------------------
    // Same names and roles as the light twin, but each hue is pulled down to
    // roughly three quarters of its light-theme luminance. They cover whole
    // blocks here rather than 3px outlines, and the light theme's values at
    // that area are a lamp — which is the one thing this theme exists to avoid.
    "acc_yellow": "#d9b833",
    "acc_pink": "#d95a8e",
    "acc_cyan": "#2db5aa",
    "acc_lime": "#a5cc31",
    "acc_orange": "#d97739",
    "acc_violet": "#9784d9"
  })


  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
