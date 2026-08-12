// Wifi status. The body toggles the radio; the chevron opens the network list.

import "../../consts"
import "../../shared/state"
import "../../shared/watchers"

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
    anchors.leftMargin: ControlMetrics.px(16)
    anchors.rightMargin: ControlMetrics.px(6)
    spacing: ControlMetrics.px(13)

    TileIcon {
      Layout.alignment: Qt.AlignVCenter
      name: "wifi"
      size: ControlMetrics.px(26)
      color: Theme.get_color("fg")
      bars: NetworkWatcher.bars(NetworkWatcher.strength)
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
        font.pixelSize: ControlMetrics.px(15)
        font.weight: 600
        color: Theme.get_color("fg")
        opacity: tile.connected ? 1.0 : 0.80
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        text: tile.subtitle
        visible: tile.subtitle !== ""
        font.family: "Noto Sans"
        font.pixelSize: ControlMetrics.px(11)
        color: Theme.get_color("muted")
        elide: Text.ElideRight
      }
    }

    // Its own hit area, so the body's radio toggle and this do not fight. It
    // sits above ControlTile's MouseArea in the stacking order, so it wins the
    // clicks that land on it and lets the rest through.
    Item {
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredWidth: ControlMetrics.px(34)
      Layout.fillHeight: true

      TileIcon {
        anchors.centerIn: parent
        name: "chevronRight"
        size: ControlMetrics.px(20)
        color: Theme.get_color("fg")
        opacity: chevron.containsMouse ? 1.0 : 0.55
        Behavior on opacity { NumberAnimation { duration: 120 } }
      }

      MouseArea {
        id: chevron
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ControlCenterState.showWifi()
      }
    }
  }
}
