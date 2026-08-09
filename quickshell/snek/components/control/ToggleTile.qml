// A two-state toggle. Shared by mute and airplane mode.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  property string icon: ""
  property string label: ""
  property bool active: false

  // Same idiom as the alert states elsewhere: the rim collapses to a single
  // colour to signal state. Cyan rather than red because this is a mode, not a
  // warning.
  edgeColor: tile.active ? SnekStyles.get_color("glass_edge_alt") : SnekStyles.get_color("glass_edge")
  edgeColorAlt: SnekStyles.get_color("glass_edge_alt")

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 5

    TileIcon {
      Layout.alignment: Qt.AlignHCenter
      name: tile.icon
      size: 22
      color: SnekStyles.get_color("fg")
      muted: tile.icon === "speaker" && tile.active
      opacity: tile.active ? 1.0 : (tile.hovered ? 0.85 : 0.65)
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: tile.label
      font.family: "Oswald"
      font.pixelSize: 11
      font.weight: 500
      color: SnekStyles.get_color("fg")
      opacity: tile.active ? 1.0 : (tile.hovered ? 0.85 : 0.65)
    }
  }
}
