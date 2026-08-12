import "../../shared/watchers"
import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

SidebarPill {
  id: root
  implicitHeight: 30
  Layout.bottomMargin: 10

  ColumnLayout {
    anchors.fill: parent
    spacing: 1
    NumberDisplay {
      id: display
      text: get_text()
      font.pixelSize: get_size()

      function get_size(): int {
        if (BatteryWatcher.percentage == 100) return 12;
        if (BatteryWatcher.percentage >= 10)  return 14;
        else                                  return 16;
      }

      function get_text(): string {
        return `${BatteryWatcher.percentage}%`;
      }

      Connections {
        target: BatteryWatcher
        function onUpdate(percentage, is_charging) {
          if      (is_charging)     set_color("fg");
          else if (percentage < 25) set_color("danger");
          else if (percentage < 40) set_color("warning");
          else                      set_color("fg");
        }

        function set_color(col: string) {
          // The pill's hue carries the state, wherever the hue lands in this
          // twin. The numerals stay `fg` — coloured text on a coloured block is
          // unreadable, and the block already said it.
          display.color = Theme.get_color("fg");
          root.accent = col === "fg" ? Theme.get_color("acc_lime")
                                     : Theme.get_color(col);
        }
      }

    }
  }
}
