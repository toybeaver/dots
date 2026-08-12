import "../shared/watchers"
import "../consts"
import "calendar"
import "notifications"
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

    // Three surfaces per screen: the bar itself, and the two overlays — the
    // control center and the calendar — each covering the whole output. They
    // cannot be one window: the bar is a 45px exclusive strip and an overlay
    // must cover everything without reserving any space.
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

          SidebarNotifications {
            targetScreen: perScreen.modelData
          }
          SidebarHyprWorkspace {}
          Rectangle {
            Layout.fillHeight: true
          }
          SidebarBattery {}
          SidebarClock {}
          SidebarDate {
            targetScreen: perScreen.modelData
          }
          SidebarControl {
            targetScreen: perScreen.modelData
          }
        }
      }

      ControlCenter {
        modelData: perScreen.modelData
        barWidth: perScreen.barWidth
      }

      CalendarPopup {
        modelData: perScreen.modelData
        barWidth: perScreen.barWidth
      }

      NotificationPopup {
        modelData: perScreen.modelData
        barWidth: perScreen.barWidth
      }
    }
  }
}
