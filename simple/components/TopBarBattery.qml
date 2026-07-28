import "../modules"

import Quickshell
import QtQuick

TopBarRectangle {
  id: root
  implicitWidth: 70

  Connections {
    target: BatteryWatcher
    onUpdate: (percentage, state) => {
      if      (state === "FU" || state === "CH") root.border.color = "green";
      else if (percentage < 50)                  root.border.color = "yellow";
      else if (percentage < 25)                  root.border.color = "red";
      else                                       root.border.color = "#00a2fa";
    }
  }

  Text {
    anchors.centerIn: parent
    
    color: "white"
    font.pointSize: 12

    text: "%1%".arg(BatteryWatcher.percentage)
  }
}
