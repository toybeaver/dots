import "../modules"

import Quickshell
import QtQuick

TopBarRectangle {
  implicitWidth: 200

  border.color: NetworkWatcher.network == null ? 'red' : '#00a2fa'

  function get_text(): string {
    if (NetworkWatcher.network == null) {
      return "Disconnected";
    }
    return `Connected to ${NetworkWatcher.network.name.slice(0,2)}...`;
  }

  Text {
    anchors.centerIn: parent

    color: "white"
    font.pointSize: 12

    text: get_text()
  }
}
