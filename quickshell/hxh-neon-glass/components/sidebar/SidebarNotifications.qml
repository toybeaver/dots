// The notification bell — the first pill in the bar, above the workspace
// switcher.
//
// Left click opens the notification center. Right click silences mako, which is
// free: mako has a mode API, and this theme's mako.conf turns the
// `do-not-disturb` mode into `invisible=1`. Silenced notifications are still
// TRACKED — verified against a live daemon — so the center keeps collecting
// while the screen stays quiet, which is the only arrangement where a DND
// toggle and a notification center make sense together.

import "../../shared/watchers"
import "../../shared/state"
import "../../consts"
import "../control"

import Quickshell
import QtQuick
import QtQuick.Layouts

SidebarPill {
  id: root

  // Which screen this bar belongs to, so the center opens on the display whose
  // pill was actually clicked.
  required property var targetScreen

  implicitHeight: 40
  Layout.topMargin: 10

  // The bar's ColumnLayout contributes 5px of spacing on its own, which is not
  // enough of a gap between a button and the workspace dots below it — they
  // read as one group. Every other pill in the bar sets 10 for the same reason.
  Layout.bottomMargin: 10

  readonly property int unread: NotificationWatcher.unread

  // Rim collapses to solid magenta while something is waiting. Solid means
  // "this one" everywhere in this shell; the gradient is the resting state.
  //
  // Being OPEN gets no state of its own, unlike the control button below.
  // Opening the center marks everything read, so the rim would drop back to its
  // resting gradient in the same frame — and with a full panel on screen there
  // is nothing left for a second signal to tell you.
  edgeColor: Theme.get_color("edge")
  edgeColorAlt: root.unread > 0 ? Theme.get_color("edge")
                                : Theme.get_color("edge_alt")

  TileIcon {
    anchors.centerIn: parent

    name: "bell"
    size: 22
    color: Theme.get_color("fg")

    // Struck through while silenced, the same way the wifi icon reports a dead
    // radio.
    off: NotificationWatcher.dnd

    opacity: NotificationWatcher.dnd ? 0.4 : (root.unread > 0 ? 1.0 : 0.8)
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  // The count.
  //
  // Raw pixel sizes, not ControlMetrics.px() — the sidebar is not on that
  // scale, and neither is anything else in it. Inside the pill rather than
  // hanging off it: the bar is 45 wide and a badge overhanging the right edge
  // would be cut off by the surface.
  Rectangle {
    width: 17
    height: 15
    radius: 5

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 3
    anchors.topMargin: 3

    visible: root.unread > 0

    // Solid, not glass. At 17x15 the shader's bevel and rim have nowhere to
    // land — it renders as a smudge rather than as a badge.
    color: Theme.get_color("edge")

    Text {
      anchors.centerIn: parent

      // Two digits do not fit at this size. Past nine the exact number stops
      // being the point anyway.
      text: root.unread > 9 ? "9+" : root.unread
      font.family: "Oswald"
      font.pixelSize: 11
      font.weight: 600
      color: Theme.get_color("fg")

      // Grayscale antialiasing. The default distance-field renderer lays
      // coloured subpixel fringes on a numeral this small — measured on the
      // brutalist badge, where an orange-and-blue "3" was most of the glyph.
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) NotificationWatcher.toggleDnd();
      else NotificationCenterState.toggle(root.targetScreen);
    }
  }
}
