// The notification center's box: a header strip and a scrolling list.
//
// Fixed size, unlike the rows inside it. The list is what varies, and a panel
// that grew and shrank with it would move on screen every time a notification
// arrived — this one is top-anchored to the bell pill, so it would grow
// downward across the desktop while you were reading it.

import "../../consts"
import "../../glass"
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

  implicitWidth: ControlMetrics.px(300)
  implicitHeight: ControlMetrics.px(340)

  // Solid fill first, glass over it — the same two-layer build the control
  // center uses, at the same weights.
  Rectangle {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    color: Theme.get_color("panel")
  }

  GlassSurface {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    bevel: 5
    fresnel: 0.50
    spec: 0.14
    // Lower than the pills'. The same grain that reads as texture on a 40px
    // pill reads as noise across a surface this size.
    grain: 0.014
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

      Text {
        Layout.fillWidth: true
        Layout.fillHeight: true

        text: "NOTIFICATIONS"
        verticalAlignment: Text.AlignVCenter
        font.family: "Oswald"
        font.pixelSize: ControlMetrics.px(14)
        font.weight: 600
        font.letterSpacing: 1
        color: Theme.get_color("fg")
        elide: Text.ElideRight
      }

      // Silence. The same toggle as right-clicking the bell, put where someone
      // who never discovers the right click will still find it.
      Item {
        Layout.preferredWidth: panel.headerH
        Layout.fillHeight: true

        GlassSurface {
          anchors.fill: parent
          radius: ControlMetrics.px(8)

          // Collapsed to amber while silenced — solid rim means "this one".
          edge: NotificationWatcher.dnd ? Theme.get_color("warning")
                                        : Theme.get_color("edge")
          edge2: NotificationWatcher.dnd ? Theme.get_color("warning")
                                         : Theme.get_color("edge_alt")

          fresnel: dndHit.containsMouse ? 0.90 : 0.60
          Behavior on fresnel {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
          }
        }

        TileIcon {
          anchors.centerIn: parent
          name: "bell"
          size: ControlMetrics.px(15)
          color: Theme.get_color("fg")
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

        GlassSurface {
          anchors.fill: parent
          radius: ControlMetrics.px(8)

          fresnel: clearHit.containsMouse && NotificationWatcher.count > 0
            ? 0.90 : 0.60
          Behavior on fresnel {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
          }
        }

        Text {
          anchors.centerIn: parent

          text: "CLEAR"
          font.family: "Oswald"
          font.pixelSize: ControlMetrics.px(10)
          font.letterSpacing: 1
          color: Theme.get_color("fg")
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
          width: list.width
        }
      }

      Text {
        anchors.centerIn: parent
        visible: NotificationWatcher.count === 0

        text: NotificationWatcher.dnd ? "SILENCED" : "NOTHING WAITING"
        font.family: "Oswald"
        font.pixelSize: ControlMetrics.px(12)
        font.letterSpacing: 1
        color: Theme.get_color("muted")
      }
    }
  }
}
