import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  Variants {
    model: Quickshell.screens;


    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 30

      RowLayout {
        BarClock { }
        Text { text: UpdatedBattery.percentage }
      }
    }
  }
}
