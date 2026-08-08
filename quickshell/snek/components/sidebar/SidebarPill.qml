import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: pill

  implicitWidth: 40
  Layout.alignment: Qt.AlignRight

  // The two ends of the rim gradient. Alert states set BOTH to the same colour
  // (see SidebarBattery) so the rim collapses to solid — a half-magenta,
  // half-orange warning would read as decoration rather than a warning.
  //
  // Set explicitly rather than derived by comparing edgeColor against the
  // default: get_color() returns a string and these are `color`, so `===`
  // between them is always false and the gradient silently collapsed.
  property color edgeColor: SnekStyles.get_color("glass_edge")
  property color edgeColorAlt: SnekStyles.get_color("glass_edge_alt")

  // Set false to keep the layout and spacing but drop the surface, leaving the
  // content bare on the wallpaper. The workspace switcher uses this — its dots
  // are already a strong enough shape that a pill around them just adds noise.
  property bool glass: true

  // Draws a translucent overlay only — the real wallpaper composites through
  // from underneath, so the pill can never drift in colour from its
  // surroundings. See the header of glass.frag for why sampling it here was a
  // mistake.
  ShaderEffect {
    anchors.fill: parent
    visible: pill.glass

    fragmentShader: Qt.resolvedUrl("../../shaders/glass.frag.qsb")

    property vector2d pillSize: Qt.vector2d(pill.width, pill.height)

    property real radius: 10
    property real bevel: 3.5
    property real fresnel: 0.60
    property real spec: 0.20
    property real grain: 0.028

    property color tint: SnekStyles.get_color("glass_tint")
    property color edge: pill.edgeColor
    property color edge2: pill.edgeColorAlt
  }
}
