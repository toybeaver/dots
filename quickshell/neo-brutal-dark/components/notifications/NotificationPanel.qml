// The notification center's box: a header strip and a scrolling list.
//
// Fixed size, unlike the rows inside it. The list is what varies, and a panel
// that grew and shrank with it would move on screen every time a notification
// arrived — this one is top-anchored to the bell pill, so it would grow
// downward across the desktop while you were reading it.

import "../../consts"
import "../../brutal"
import "../../shared/watchers"
import "../control"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: panel

  readonly property int pad: ControlMetrics.px(16)
  readonly property int headerH: ControlMetrics.px(30)
  readonly property int sectionGap: ControlMetrics.px(10)

  // Room for the offset shadow of the rows, which BrutalSurface draws OUTSIDE
  // its item on the right and bottom. The ListView clips, so without this the
  // rows lose the shadow on the very side the eye reads depth from.
  readonly property int shadowRoom: ControlMetrics.px(4)

  implicitWidth: ControlMetrics.px(300)
  implicitHeight: ControlMetrics.px(340)

  BrutalSurface {
    anchors.fill: parent
    base: Theme.get_color("panel")

    // Light border, not ink, and a dim neutral shadow — the panel is the one
    // surface with no hue to derive a shadow from, and it floats on the bare
    // desktop where ink cannot be seen. Same values its control center uses.
    edge: Theme.get_color("fg")
    shadowColor: "#1a1a1e"

    borderWidth: ControlMetrics.px(4)
    offset: ControlMetrics.px(8)
  }

  // Swallows clicks that land on the panel rather than on a control, so the
  // popup's dismiss handler underneath does not fire.
  MouseArea { anchors.fill: parent }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: panel.pad
    spacing: panel.sectionGap

    // ---- header -----------------------------------------------------------
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: panel.headerH

      // Pinned, not just preferred. Every child of this row sets
      // Layout.fillHeight, which leaves the row itself with no upper bound —
      // so the ColumnLayout handed it all the slack meant for the list, and the
      // header grew to fill the panel with the notifications squeezed into a
      // 6px strip underneath.
      Layout.maximumHeight: panel.headerH

      spacing: ControlMetrics.px(6)

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        BrutalSurface {
          anchors.fill: parent
          base: Theme.get_color("acc_pink")
          edge: Theme.get_color("edge")
          shadowColor: Qt.darker(Theme.get_color("acc_pink"), 2.2)
          borderWidth: ControlMetrics.px(2)
          offset: ControlMetrics.px(3)
        }

        Text {
          anchors.centerIn: parent

          text: "NOTIFICATIONS"
          font.family: "Adwaita Sans"
          font.pixelSize: ControlMetrics.px(13)
          font.weight: 800
          color: Theme.get_color("on_block")
          elide: Text.ElideRight
        }
      }

      // Silence. The same toggle as right-clicking the bell, put where someone
      // who never discovers the right click will still find it.
      Item {
        Layout.preferredWidth: panel.headerH
        Layout.fillHeight: true

        BrutalSurface {
          anchors.fill: parent
          base: NotificationWatcher.dnd ? Theme.get_color("acc_orange")
                                        : Theme.get_color("neutral")
          edge: Theme.get_color("edge")
          shadowColor: Qt.darker(NotificationWatcher.dnd
            ? Theme.get_color("acc_orange") : Theme.get_color("neutral"), 2.2)
          borderWidth: ControlMetrics.px(2)
          offset: ControlMetrics.px(3)
          pressed: dndHit.containsMouse
        }

        TileIcon {
          anchors.centerIn: parent
          name: "bell"
          size: ControlMetrics.px(15)
          color: Theme.get_color("on_block")
          off: NotificationWatcher.dnd
        }

        MouseArea {
          id: dndHit
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: NotificationWatcher.toggleDnd()
        }
      }

      Item {
        Layout.preferredWidth: ControlMetrics.px(48)
        Layout.fillHeight: true

        // Nothing to clear, so nothing to press. Kept in the layout rather than
        // hidden, so the header does not reflow the moment the list empties.
        opacity: NotificationWatcher.count > 0 ? 1.0 : 0.35

        BrutalSurface {
          anchors.fill: parent
          base: Theme.get_color("neutral")
          edge: Theme.get_color("edge")
          shadowColor: Qt.darker(Theme.get_color("neutral"), 2.2)
          borderWidth: ControlMetrics.px(2)
          offset: ControlMetrics.px(3)
          pressed: clearHit.containsMouse && NotificationWatcher.count > 0
        }

        Text {
          anchors.centerIn: parent

          text: "CLEAR"
          font.family: "Adwaita Sans"
          font.pixelSize: ControlMetrics.px(9)
          font.weight: 800
          color: Theme.get_color("on_block")
        }

        MouseArea {
          id: clearHit
          anchors.fill: parent
          enabled: NotificationWatcher.count > 0
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: NotificationWatcher.clearAll()
        }
      }
    }

    // ---- the list ---------------------------------------------------------
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      ListView {
        id: list

        anchors.fill: parent
        clip: true
        spacing: ControlMetrics.px(6)

        model: NotificationWatcher.list

        delegate: NotificationRow {
          required property var modelData

          item: modelData
          width: list.width - panel.shadowRoom
        }
      }

      Text {
        anchors.centerIn: parent
        visible: NotificationWatcher.count === 0

        text: NotificationWatcher.dnd ? "SILENCED" : "NOTHING WAITING"
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(11)
        font.weight: 800
        color: Theme.get_color("fg")
        opacity: 0.35
      }
    }
  }
}
