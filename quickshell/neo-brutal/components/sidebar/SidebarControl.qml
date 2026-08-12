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

  // Outline goes to `edge_alt` while open, the same way the toggle tiles inside mark
  // themselves active.
  // Violet at rest, matching the active window border — the one pill in the bar
  // that opens something gets the same colour as the thing focus is drawn in.
  // Pink while open, so the button still reports its own state.
  accent: root.open ? Theme.get_color("acc_pink") : Theme.get_color("acc_violet")
  edgeColor: root.open ? Theme.get_color("edge_alt")
                       : Theme.get_color("edge")

  ArchLogo {
    anchors.centerIn: parent

    // Solid white, no outline. Everything else in this theme is ink-on-colour,
    // but the mark sits on a saturated block and a black-outlined white glyph
    // at 24px turns into mud — the outline eats the thin ankle of each leg.
    color: "#ffffff"

    // Square, unlike the 120x78 mark it replaced, so height is now the binding
    // constraint in a 40px pill rather than width.
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
