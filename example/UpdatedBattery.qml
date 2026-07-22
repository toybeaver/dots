pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
  id: root
  property string percentage: {
    UPower.displayDevice.percentage*100+"%"  
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: percentage = UPower.displayDevice.percentage*100+"%"
  }
}
