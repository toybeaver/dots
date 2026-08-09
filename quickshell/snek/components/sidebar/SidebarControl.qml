// The control center button — the last pill in the bar, below the date.

import "../../consts"
import "../../state"

import Quickshell
import QtQuick
import QtQuick.Layouts

SidebarPill {
  id: root

  // Which screen this bar belongs to, so the panel opens on the display whose
  // button was actually clicked.
  required property var targetScreen

  implicitHeight: 40
  Layout.bottomMargin: 10

  readonly property bool open: ControlCenterState.open
    && ControlCenterState.screen === root.targetScreen

  // Rim collapses to cyan while open, the same way the toggle tiles inside mark
  // themselves active.
  edgeColor: root.open ? SnekStyles.get_color("glass_edge_alt")
                       : SnekStyles.get_color("glass_edge")

  HxhLogo {
    anchors.centerIn: parent

    // The mark is 120x78 and its serifs stop resolving below roughly 30px wide,
    // so it is drawn as wide as a 40px pill allows rather than at some nominal
    // icon size.
    size: 32

    opacity: root.open || mouse.containsMouse ? 1.0 : 0.80
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: ControlCenterState.toggle(root.targetScreen)
  }
}
