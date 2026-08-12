pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  readonly property string y: {
    Qt.formatDateTime(clock.date, "yy")
  }
  readonly property string mo: {
    Qt.formatDateTime(clock.date, "MM")
  }
  readonly property string d: {
    Qt.formatDateTime(clock.date, "dd")
  }
  readonly property string h: {
    Qt.formatDateTime(clock.date, "HH")
  }
  readonly property string m: {
    Qt.formatDateTime(clock.date, "mm")
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
