import "../../watchers"
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
          else if (percentage < 40) set_color("warning");
          else if (percentage < 25) set_color("danger");
          else                      set_color("fg");
        }

        function set_color(col: string) {
          display.color = SnekStyles.get_color(col);
          root.border.color = SnekStyles.get_color(col);
        }
      }

    }
  }
}
