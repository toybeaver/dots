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
