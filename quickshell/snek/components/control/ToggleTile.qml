// A two-state toggle. Shared by mute and airplane mode.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  property string icon: ""
  property bool active: false

  // Same idiom as the alert states elsewhere: the rim collapses to a single
  // colour to signal state. Cyan rather than red because this is a mode, not a
  // warning.
  edgeColor: tile.active ? SnekStyles.get_color("glass_edge_alt") : SnekStyles.get_color("glass_edge")
  edgeColorAlt: SnekStyles.get_color("glass_edge_alt")

  TileIcon {
    anchors.centerIn: parent
    name: tile.icon
    size: ControlMetrics.px(30)
    color: SnekStyles.get_color("fg")
    muted: tile.icon === "speaker" && tile.active
    opacity: tile.active ? 1.0 : (tile.hovered ? 0.85 : 0.65)
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }
}
