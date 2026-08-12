import "../../shared/watchers"
import "../../consts"

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

SidebarPill {
  implicitHeight: 80
  Layout.bottomMargin: 10

  // A post-it like every other reading in the bar. The other themes leave
  // these dots bare, because a pill around an already-strong shape just adds
  // noise — but in this theme the block IS the design language, and the
  // workspace switcher was the only thing floating loose on the wallpaper.
  //
  // Orange, the same hue the restart tile carries in the control center. This
  // was `neutral` first, on the reasoning that the dots already say which
  // workspace you are on through fill and position and a colour on top of that
  // is one signal too many — true as far as it goes, but it left the top of the
  // bar reading as two pale blocks with nothing to tell them apart.
  accent: Theme.get_color("acc_orange")

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

        border.color: Theme.get_color("on_block")
        border.width: 2

        radius: 100

        function get_fill_color() {
          if (index == Hyprland.focusedWorkspace.id -1) {
            return Theme.get_color("on_block")
          }
          return "transparent"
        }
      }
    }
  }
}
