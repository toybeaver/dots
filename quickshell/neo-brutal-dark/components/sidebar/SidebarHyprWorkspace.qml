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
  // `neutral`, not a hue — a white block in the light twin, a plain off-white
  // outline in the dark one. The workspace dots already carry meaning through
  // fill and position, so a colour on top of that is one signal too many.
  accent: Theme.get_color("neutral")

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
