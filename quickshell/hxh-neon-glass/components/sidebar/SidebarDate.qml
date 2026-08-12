import "../../shared/watchers"
import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

SidebarPill {
  implicitHeight: 110
  Layout.bottomMargin: 10

  ColumnLayout {
    anchors.fill: parent
    spacing: 1
    NumberDisplay {
      text: TimeWatcher.d
    }
    Separator {
      implicitWidth: 10
    }
    NumberDisplay {
      text: TimeWatcher.mo
    }
    Separator {
      implicitWidth: 10
    }
    NumberDisplay {
      text: TimeWatcher.y
    }
  }
}
