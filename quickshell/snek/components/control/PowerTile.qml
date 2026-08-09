// Power off / restart / log out.
//
// Arm-then-confirm, mirroring the MOD+SHIFT+Q bind in hyprland.lua right down to
// the 3 second window, so both ways out of the session behave the same. The
// panel owns which tile is armed (see ControlPanel) — arming one disarms the
// others, and closing the panel disarms everything.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  property string icon: ""
  property string label: ""
  property bool armed: false

  // Collapsing both ends of the rim to one colour is how state is signalled
  // everywhere in this shell — see SidebarBattery. A half-red rim would read as
  // decoration rather than as a warning.
  edgeColor: tile.armed ? SnekStyles.get_color("danger") : SnekStyles.get_color("glass_edge")
  edgeColorAlt: tile.armed ? SnekStyles.get_color("danger") : SnekStyles.get_color("glass_edge_alt")

  ColumnLayout {
    anchors.centerIn: parent
    spacing: ControlMetrics.px(5)

    TileIcon {
      Layout.alignment: Qt.AlignHCenter
      name: tile.icon
      size: ControlMetrics.px(22)
      color: tile.armed ? SnekStyles.get_color("danger") : SnekStyles.get_color("fg")
      opacity: tile.armed || tile.hovered ? 1.0 : 0.75
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: tile.armed ? "sure?" : tile.label
      font.family: "Oswald"
      font.pixelSize: ControlMetrics.px(11)
      font.weight: 500
      color: tile.armed ? SnekStyles.get_color("danger") : SnekStyles.get_color("fg")
      opacity: tile.armed || tile.hovered ? 1.0 : 0.75
    }
  }
}
