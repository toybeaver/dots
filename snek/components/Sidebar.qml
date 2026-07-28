import "../watchers"
import "../consts"
import "sidebar"

import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      color: "transparent"

      implicitWidth: 45
      anchors {
        top: true
        bottom: true
        left: true
      }

      ColumnLayout {
        anchors.fill: parent
        
        Rectangle { 
          Layout.fillHeight: true
        }
        SidebarBattery {}
        SidebarClock {}
        SidebarDate {}
      }
    }
  }
}
