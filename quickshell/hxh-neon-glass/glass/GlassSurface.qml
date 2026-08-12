// The glass surface, as a reusable element.
//
// This was inlined in SidebarPill until the control center needed the same
// effect at a larger radius. Every default below is exactly what the pill used,
// so the sidebar is unchanged by the extraction — if you retune anything here,
// you are retuning the whole shell at once.
//
// Draws a translucent overlay only. It deliberately does NOT sample what is
// behind it: the real wallpaper composites through from underneath, so a surface
// can never drift in colour from its surroundings. See the header of
// shaders/glass.frag for why sampling was tried and abandoned.

import "../consts"

import Quickshell
import QtQuick

ShaderEffect {
  fragmentShader: Qt.resolvedUrl("../shaders/glass.frag.qsb")

  // The shader needs its own pixel size to evaluate the rounded-box signed
  // distance field — it cannot derive that from the vertex stage alone.
  property vector2d pillSize: Qt.vector2d(width, height)

  property real radius: 10
  property real bevel: 3.5
  property real fresnel: 0.60
  property real spec: 0.20
  property real grain: 0.028

  property color tint: Theme.get_color("tint")

  // The two ends of the rim gradient, running along Hyprland's 45 degree border
  // axis. Collapsing both to one colour turns the rim solid, which is how state
  // is signalled everywhere in this shell — see SidebarBattery.
  property color edge: Theme.get_color("edge")
  property color edge2: Theme.get_color("edge_alt")
}
