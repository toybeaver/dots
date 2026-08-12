import "../shared/watchers"
import "../consts"
import "control"
import "sidebar"

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    // Two surfaces per screen: the bar itself, and the control center overlay
    // that covers the whole output. They cannot be one window — the bar is a
    // 45px exclusive strip and the overlay must cover everything without
    // reserving any space.
    Scope {
      id: perScreen

      required property var modelData

      // One source of truth for the bar's width: the sidebar reserves it, and
      // the control center needs it to position itself clear of the bar.
      readonly property int barWidth: 45

      PanelWindow {
        screen: perScreen.modelData

        // Named so hyprland.lua can target this surface with the glass layer rule.
        WlrLayershell.namespace: Theme.sidebarLayer

        color: "transparent"

        implicitWidth: perScreen.barWidth
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
          SidebarControl {
            targetScreen: perScreen.modelData
          }
        }
      }

      ControlCenter {
        modelData: perScreen.modelData
        barWidth: perScreen.barWidth
      }
    }
  }
}
