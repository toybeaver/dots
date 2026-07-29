import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: pill

  implicitWidth: 40
  Layout.alignment: Qt.AlignRight

  // Alert states tint the rim (see SidebarBattery).
  property color edgeColor: SnekStyles.get_color("glass_edge")

  // Draws a translucent overlay only — the real wallpaper composites through
  // from underneath, so the pill can never drift in colour from its
  // surroundings. See the header of glass.frag for why sampling it here was a
  // mistake.
  ShaderEffect {
    anchors.fill: parent

    fragmentShader: Qt.resolvedUrl("../../shaders/glass.frag.qsb")

    property vector2d pillSize: Qt.vector2d(pill.width, pill.height)

    property real radius: 10
    property real bevel: 3.5
    property real fresnel: 0.13
    property real spec: 0.22
    property real grain: 0.028

    property color tint: SnekStyles.get_color("glass_tint")
    property color edge: pill.edgeColor
  }
}
