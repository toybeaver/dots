import "../watchers"
import "../consts"
import "sidebar"

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      // Named so hyprland.lua can target this surface with the glass layer rule.
      WlrLayershell.namespace: "snek-sidebar"

      color: "transparent"

      implicitWidth: 45
      anchors {
        top: true
        bottom: true
        left: true
      }

      ColumnLayout {
        anchors.fill: parent
        
        SidebarHyprWorkspace {
          Layout.topMargin: 10
        }
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
