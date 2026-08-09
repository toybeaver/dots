// The wifi page: back arrow, the connected network, refresh, and the list.

import "../../../consts"
import "../../../state"
import "../../../watchers"
import ".."

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: view

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
          color: SnekStyles.get_color("fg")
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
      Layout.fillWidth: true
    }

    // ---- refresh ----
    RowLayout {
      Layout.fillWidth: true
      spacing: ControlMetrics.px(10)

      Text {
        text: "networks"
        font.family: "Oswald"
        font.pixelSize: ControlMetrics.px(11)
        font.weight: 500
        color: SnekStyles.get_color("muted")
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: SnekStyles.get_color("fg")
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
          color: SnekStyles.get_color("fg")
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
        width: list.width
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

        color: SnekStyles.get_color("fg")
        opacity: 0.22
      }

      Text {
        anchors.centerIn: parent
        visible: list.count === 0
        text: NetworkWatcher.wifiEnabled ? "No networks found" : "Wi-Fi is off"
        font.family: "Noto Sans"
        font.pixelSize: ControlMetrics.px(12)
        color: SnekStyles.get_color("muted")
      }
    }
  }
}
