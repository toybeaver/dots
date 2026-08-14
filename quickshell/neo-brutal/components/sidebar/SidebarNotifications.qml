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

  pressed: hit.pressed

  // The bar's ColumnLayout contributes 5px of spacing on its own, which is not
  // enough of a gap between a button and the workspace dots below it — they
  // read as one group. Every other pill in the bar sets 10 for the same reason.
  Layout.bottomMargin: 10

  readonly property int unread: NotificationWatcher.unread

  // Pink while something is waiting, plain white otherwise.
  //
  // Being OPEN gets no colour of its own, unlike the other two buttons in the
  // bar. Opening the center marks everything read, so the pill would flip out
  // of its "waiting" hue in the same frame — and with a full panel on screen
  // there is nothing left for a second colour to tell you.
  accent: root.unread > 0 ? Theme.get_color("acc_pink")
                          : Theme.get_color("neutral")

  // Where this pill's top edge sits, measured down from the top of the bar. The
  // center lines its own top up with it — the mirror of what SidebarDate does
  // at the other end. Measured rather than written down for the same reason.
  readonly property real topInset: root.y

  onTopInsetChanged: NotificationCenterState.anchorInset = root.topInset
  Component.onCompleted: NotificationCenterState.anchorInset = root.topInset

  TileIcon {
    anchors.centerIn: parent

    name: "bell"
    size: 20
    color: Theme.get_color("on_block")

    // Struck through while silenced, the same way the wifi icon reports a dead
    // radio.
    off: NotificationWatcher.dnd

    opacity: NotificationWatcher.dnd ? 0.45 : 1.0
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  // The count, as an ink stamp in the corner.
  //
  // NO BORDER, and inset well clear of the pill's own. The first version was a
  // pale block with a 2px ink outline sitting flush against the pill edge, and
  // the two blacks fused: instead of a badge on a block it read as a notch
  // bitten out of the pill's border. Solid ink with the numeral knocked out of
  // it has nothing to fuse with, and is the more brutalist of the two anyway.
  //
  // Raw pixel sizes, not ControlMetrics.px() — the sidebar is not on that
  // scale, and neither is anything else in it. Inside the pill rather than
  // hanging off it: the bar is 56 wide and a badge overhanging the right edge
  // would be cut off by the surface.
  Rectangle {
    width: 17
    height: 14

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 5
    anchors.topMargin: 5

    visible: root.unread > 0

    color: Theme.get_color("edge")
    radius: 0
    antialiasing: false

    Text {
      anchors.centerIn: parent

      // Two digits do not fit at this size. Past nine the exact number stops
      // being the point anyway.
      text: root.unread > 9 ? "9+" : root.unread
      font.family: "Adwaita Sans"
      font.pixelSize: 11
      font.weight: 700
      color: Theme.get_color("neutral")

      // Grayscale antialiasing. The default rasteriser was laying coloured
      // subpixel fringes on a 10px bold numeral — orange down one side of the
      // glyph and blue down the other, which at this size is most of the
      // character.
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    // `hit`, not `mouse`: the click handler below takes a parameter of that
    // name, and an id it shadows is a trap for the next reader.
    id: hit

    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) NotificationWatcher.toggleDnd();
      else NotificationCenterState.toggle(root.targetScreen);
    }
  }
}
