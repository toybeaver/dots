// The control center button — the last pill in the bar, below the date.

import "../../consts"
import "../../shared/state"

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
  edgeColor: root.open ? Theme.get_color("edge_alt")
                       : Theme.get_color("edge")

  HxhLogo {
    anchors.centerIn: parent

    // The mark is 120x78, so width is the binding constraint in a 40px pill —
    // at 32 it left only 4px either side and read as cramped. 26 gives it 7px
    // of air, closer to the vertical breathing room it already had.
    //
    // Do not push much below this: the serifs are 6 units of 78, so they land
    // near a single pixel and start to mush.
    size: 26

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
