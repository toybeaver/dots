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
      // Wider than the other themes' 45. Every pill carries a hard border and
      // a 4px offset shadow, which together eat 14px of a pill's width before
      // any content is drawn — at 45 the readings were clamped against their
      // own borders and a 100% battery overflowed its block.
      readonly property int barWidth: 56

      PanelWindow {
        screen: perScreen.modelData

        // Named so hyprland.lua can scope layer rules to this theme alone.
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
