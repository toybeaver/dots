import "../../shared/watchers"
import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

SidebarPill {
  implicitHeight: 70
  Layout.bottomMargin: 10

  ColumnLayout {
    anchors.fill: parent
    spacing: 1
    NumberDisplay {
      text: TimeWatcher.h
    }
    Separator {}
    NumberDisplay {
      text: TimeWatcher.m
    }
  }
}
