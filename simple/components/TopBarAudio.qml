import "../modules"

import Quickshell
import QtQuick

TopBarRectangle {
  implicitWidth: 90

  border.color: AudioWatcher.muted ? 'red' : '#00a2fa'

  function get_text(): string {
    return `Vol: ${AudioWatcher.muted ? 'MM' : `${AudioWatcher.volume}%`}`;
  }

  Text {
    anchors.centerIn: parent

    color: "white"
    font.pointSize: 12

    text: get_text()
  }
}
