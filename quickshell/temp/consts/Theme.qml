pragma Singleton

import Quickshell
import QtQuick

// The flat theme: white on black, hairline outlines, square corners, no shader
// and no compositor blur.
//
// It exists to prove the theme split holds — that a theme can differ in
// material and not just in hue — and to be the thing you copy when starting
// claymorphism or neo-brutalism. Nothing here is sampled from the wallpaper, so
// unlike hxh-neon-glass it stays correct whatever is behind it.
Singleton {
  id: root

  // Identity. `name` MUST match this directory's name — it is what the theme
  // switcher hands to bin/shell-theme, and what the layer namespaces below are
  // built from. `label` is the only part the user ever sees.
  readonly property string name: "temp"
  readonly property string label: "Temp"

  readonly property string sidebarLayer: root.name + "-sidebar"
  readonly property string controlLayer: root.name + "-control"

  // Deliberately almost monochrome. The two exceptions are `warning` and
  // `danger`, kept because they are the only carriers of information that has
  // no other channel here: a low battery and a failed wifi connection both
  // signal by collapsing an outline to a single colour, and in a palette with
  // no colour they would collapse to something indistinguishable from normal.
  // Every other token is a shade of grey.
  readonly property var colors: ({
    "bg": "#000000",

    "fg": "#ffffff",
    "warning": "#ffc24b",
    "danger": "#ff4060",

    // Secondary text — the IP under the SSID, a security type in the network
    // list. Far enough below `fg` to read as subordinate on pure black.
    "muted": "#8a8a8a",

    // Tile and pill fill, in #AARRGGBB. Nearly opaque black rather than a
    // translucent white wash: with no blur behind it, anything see-through
    // just picks up whatever window is underneath and stops reading as a
    // surface at all.
    "surface": "#d9000000",

    // The control center slab. Denser still than the tiles — it is the largest
    // surface in the shell and carries the most text.
    //
    // No blur rule exists for this theme (see hyprland.lua), so unlike
    // hxh-neon-glass there is no ignore_alpha threshold this has to stay above.
    "panel": "#f2000000",

    // Outlines. `edge` is the resting hairline and gets multiplied down by
    // Surface.fresnel, so it is set brighter than it looks: at the default
    // 0.60 it lands around mid grey, and hover lifting fresnel to 0.90 is what
    // makes the outline brighten.
    //
    // `edge_alt` is state — a mode engaged, a network connecting. Pure white
    // against a grey resting edge is the whole of this theme's state language,
    // since there is no gradient here to collapse.
    "edge": "#b4b4b4",
    "edge_alt": "#ffffff"
  })


  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
