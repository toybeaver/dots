// A two-state toggle. Shared by mute and airplane mode.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  property string icon: ""
  property bool active: false

  // Engaged lights the tile in its own hue; idle drops it to neutral. Colour
  // IS the state — there is nothing else in this style that can carry it.
  property color activeColor: Theme.get_color("acc_cyan")

  accent: tile.active ? tile.activeColor : Theme.get_color("neutral")

  TileIcon {
    anchors.centerIn: parent
    name: tile.icon
    size: ControlMetrics.px(30)
    color: Theme.get_color("on_block")
    muted: tile.icon === "speaker" && tile.active
    opacity: tile.active ? 1.0 : (tile.hovered ? 0.85 : 0.65)
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }
}
