import "../modules"

import Quickshell
import QtQuick

TopBarRectangle {
  implicitWidth: 160

  Text {
    anchors.centerIn: parent
    
    color: "white"
    font.pointSize: 12

    text: "%1 %2".arg(TimeWatcher.date).arg(TimeWatcher.time)
  }
}
