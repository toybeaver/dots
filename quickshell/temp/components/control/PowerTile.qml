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
  property bool armed: false

  // Armed shows as a `danger` outline — one of only two places this theme
  // spends a colour at all, see the note in consts/Theme.qml. Both ends are set
  // for parity with hxh-neon-glass, where they are a gradient; here the second is
  // ignored.
  edgeColor: tile.armed ? Theme.get_color("danger") : Theme.get_color("edge")
  edgeColorAlt: tile.armed ? Theme.get_color("danger") : Theme.get_color("edge_alt")

  TileIcon {
    anchors.centerIn: parent
    name: tile.icon
    size: ControlMetrics.px(30)
    color: tile.armed ? Theme.get_color("danger") : Theme.get_color("fg")
    opacity: tile.armed || tile.hovered ? 1.0 : 0.75
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  // The one piece of text kept on these tiles, and only while armed.
  //
  // The rim and icon both go danger red, which is a strong signal, but these
  // three actions are irreversible and a red icon alone does not say "this
  // click will do it". Anchored to the bottom rather than stacked under the
  // icon so arming does not shift the icon.
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: ControlMetrics.px(8)

    visible: tile.armed
    text: "sure?"
    font.family: "Oswald"
    font.pixelSize: ControlMetrics.px(11)
    font.weight: 500
    color: Theme.get_color("danger")
  }
}
