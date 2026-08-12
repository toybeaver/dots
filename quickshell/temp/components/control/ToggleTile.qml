// A two-state toggle. Shared by mute and airplane mode.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  property string icon: ""
  property bool active: false

  // Same idiom as the alert states elsewhere, but this theme has no gradient to
  // collapse: state shows as a brighter outline instead. Not `danger`, because
  // this is a mode rather than a warning.
  edgeColor: tile.active ? Theme.get_color("edge_alt") : Theme.get_color("edge")
  edgeColorAlt: Theme.get_color("edge_alt")

  TileIcon {
    anchors.centerIn: parent
    name: tile.icon
    size: ControlMetrics.px(30)
    color: Theme.get_color("fg")
    muted: tile.icon === "speaker" && tile.active
    opacity: tile.active ? 1.0 : (tile.hovered ? 0.85 : 0.65)
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }
}
