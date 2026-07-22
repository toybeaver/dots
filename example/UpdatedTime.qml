// SAME THING AS Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root
  readonly property string time: {
    Qt.formatDateTime(clock.date, "yyyy/MM/dd - HH:mm")
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
