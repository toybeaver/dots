// Wifi status, and a toggle for the radio.

import "../../consts"
import "../../watchers"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  readonly property bool connected: NetworkWatcher.wifiEnabled && NetworkWatcher.ssid !== ""

  readonly property string title: {
    if (!NetworkWatcher.wifiPresent) return "No adapter";
    if (!NetworkWatcher.wifiEnabled) return "Wi-Fi off";
    if (NetworkWatcher.ssid === "") return "Not connected";
    return NetworkWatcher.ssid;
  }

  // Only meaningful while associated — an address left over from a previous
  // network would be worse than showing nothing.
  readonly property string subtitle: tile.connected ? NetworkWatcher.ipv4 : ""

  onClicked: NetworkWatcher.setWifi(!NetworkWatcher.wifiEnabled)

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 14
    spacing: 13

    TileIcon {
      Layout.alignment: Qt.AlignVCenter
      name: "wifi"
      size: 26
      color: SnekStyles.get_color("fg")
      level: NetworkWatcher.strength
      off: !NetworkWatcher.wifiPresent || !NetworkWatcher.wifiEnabled
      opacity: tile.connected ? 1.0 : (tile.hovered ? 0.85 : 0.65)
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 1

      Text {
        Layout.fillWidth: true
        text: tile.title
        font.family: "Oswald"
        font.pixelSize: 15
        font.weight: 600
        color: SnekStyles.get_color("fg")
        opacity: tile.connected ? 1.0 : 0.80
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        text: tile.subtitle
        visible: tile.subtitle !== ""
        font.family: "Noto Sans"
        font.pixelSize: 11
        color: SnekStyles.get_color("muted")
        elide: Text.ElideRight
      }
    }
  }
}
