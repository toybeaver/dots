// The wifi page: back arrow, the connected network, refresh, and the list.

import "../../../consts"
import "../../../shared/state"
import "../../../shared/watchers"
import ".."

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: view

  // Room for the right-hand shadow, the same reservation MainView makes.
  // BrutalSurface overflows its item bottom-right, and both the panel viewport
  // and the ListView clip — so without this the rows and the header kept their
  // bottom shadow and silently lost the right one.
  readonly property int shadowRoom: ControlMetrics.px(5)

  ColumnLayout {
    anchors.fill: parent
    spacing: ControlMetrics.px(8)

    // ---- back ----
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ControlMetrics.px(20)

      Item {
        width: ControlMetrics.px(30)
        height: parent.height

        TileIcon {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          name: "chevronLeft"
          size: ControlMetrics.px(18)
          color: Theme.get_color("fg")
          opacity: back.containsMouse ? 1.0 : 0.6
          Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
          id: back
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: ControlCenterState.showMain()
        }
      }
    }

    // ---- connected network ----
    WifiHeader {
      Layout.rightMargin: view.shadowRoom
      Layout.fillWidth: true
    }

    // ---- refresh ----
    RowLayout {
      Layout.fillWidth: true
      spacing: ControlMetrics.px(10)

      Text {
        text: "networks"
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(11)
        font.weight: 500
        color: Theme.get_color("muted")
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.get_color("fg")
        opacity: 0.12
      }

      // A plain button. There is no "scan finished" signal on WifiDevice, so
      // anything animated here would be timing a spinner against nothing.
      Item {
        Layout.preferredWidth: ControlMetrics.px(28)
        Layout.preferredHeight: ControlMetrics.px(22)

        TileIcon {
          anchors.centerIn: parent
          name: "refresh"
          size: ControlMetrics.px(17)
          color: Theme.get_color("fg")
          opacity: refresh.containsMouse ? 1.0 : 0.6
          Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
          id: refresh
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: NetworkWatcher.refresh()
        }
      }
    }

    // ---- the list ----
    ListView {
      id: list

      Layout.fillWidth: true
      Layout.fillHeight: true

      clip: true
      spacing: ControlMetrics.px(5)
      boundsBehavior: Flickable.StopAtBounds

      // The connected network is promoted into the header, so it is filtered
      // out here rather than appearing twice.
      model: NetworkWatcher.networks.filter(n => n && !n.connected)

      delegate: WifiNetworkRow {
        required property var modelData
        network: modelData
        width: list.width - view.shadowRoom
      }

      // Hand-rolled rather than QtQuick.Controls' ScrollBar: nothing else in
      // this shell pulls in Controls, and its default style would land here
      // unthemed. Purely an indicator — the wheel already scrolls the list.
      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 1
        width: 3
        radius: 1.5

        visible: list.contentHeight > list.height
        y: list.visibleArea.yPosition * list.height
        height: Math.max(ControlMetrics.px(20), list.visibleArea.heightRatio * list.height)

        color: Theme.get_color("fg")
        opacity: 0.22
      }

      Text {
        anchors.centerIn: parent
        visible: list.count === 0
        text: NetworkWatcher.wifiEnabled ? "No networks found" : "Wi-Fi is off"
        font.family: "Noto Sans"
        font.pixelSize: ControlMetrics.px(12)
        color: Theme.get_color("muted")
      }
    }
  }
}
