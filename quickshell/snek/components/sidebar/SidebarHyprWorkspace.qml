import "../../watchers"
import "../../consts"

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

SidebarPill {
  implicitHeight: 80
  Layout.bottomMargin: 10

  // Bare dots, no glass surface — see SidebarPill.glass.
  glass: false

  ColumnLayout {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: 80
    spacing: 3

    Repeater {
      model: 5
      Rectangle {
        required property int index

        Layout.alignment: Qt.AlignHCenter
        width: 10
        height: 10
        color: get_fill_color()

        border.color: SnekStyles.get_color("fg")
        border.width: 2

        radius: 100

        function get_fill_color() {
          if (index == Hyprland.focusedWorkspace.id -1) {
            return SnekStyles.get_color("fg")
          }
          return "transparent"
        }
      }
    }
  }
}
