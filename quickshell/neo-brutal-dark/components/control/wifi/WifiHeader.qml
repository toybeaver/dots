// The connected network, at the top of the wifi page.
//
// This network is deliberately absent from the list below — it is promoted up
// here instead, so it is never shown twice.

import "../../../consts"
import "../../../brutal"
import "../../../shared/watchers"
import ".."

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: header

  readonly property var network: NetworkWatcher.activeNetwork
  readonly property bool connected: NetworkWatcher.wifiEnabled && header.network !== null

  implicitHeight: ControlMetrics.px(52)

  BrutalSurface {
    anchors.fill: parent
    base: Theme.get_color("acc_yellow")
    edge: Theme.get_color("edge")
    shadowColor: Qt.darker(Theme.get_color("acc_yellow"), 2.2)
  }


  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: ControlMetrics.px(14)
    anchors.rightMargin: ControlMetrics.px(10)
    spacing: ControlMetrics.px(12)

    TileIcon {
      Layout.alignment: Qt.AlignVCenter
      name: "wifi"
      size: ControlMetrics.px(24)
      color: Theme.get_color("on_block")
      bars: NetworkWatcher.bars(NetworkWatcher.strength)
      off: !header.connected
      opacity: header.connected ? 1.0 : 0.5
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 1

      Text {
        Layout.fillWidth: true
        text: header.connected ? NetworkWatcher.ssid
            : (NetworkWatcher.wifiEnabled ? "Not connected" : "Wi-Fi off")
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(15)
        font.weight: 800
        color: Theme.get_color("on_block")
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: header.connected
        text: {
          if (!header.network) return "";
          const sec = NetworkWatcher.securityLabel(header.network.security);
          const ip = NetworkWatcher.ipv4;
          return ip !== "" && sec !== "" ? `${ip}  ·  ${sec}` : (ip !== "" ? ip : sec);
        }
        font.family: "Noto Sans"
        font.pixelSize: ControlMetrics.px(11)
        color: Theme.get_color("on_block_dim")
        elide: Text.ElideRight
      }
    }

    // Text rather than an icon: there is no glyph that unambiguously says
    // "disconnect" as opposed to "turn the radio off", and confusing those two
    // here would be costly.
    Item {
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredWidth: disconnectLabel.implicitWidth + ControlMetrics.px(18)
      Layout.preferredHeight: ControlMetrics.px(28)
      visible: header.connected

      Rectangle {
        anchors.fill: parent
        radius: ControlMetrics.px(6)
        color: Theme.get_color("on_block")
        opacity: disconnectMouse.containsMouse ? 0.16 : 0.08
        Behavior on opacity { NumberAnimation { duration: 120 } }
      }

      Text {
        id: disconnectLabel
        anchors.centerIn: parent
        text: "disconnect"
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(11)
        font.weight: 500
        color: Theme.get_color("on_block")
        opacity: disconnectMouse.containsMouse ? 1.0 : 0.75
      }

      MouseArea {
        id: disconnectMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NetworkWatcher.disconnectActive()
      }
    }
  }
}
