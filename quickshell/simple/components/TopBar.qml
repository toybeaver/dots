import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      color: "transparent"

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 26

      RowLayout {
        anchors.fill: parent
        Rectangle { 
          Layout.fillWidth: true
        }
        TopBarWifi { }
        TopBarAudio { }
        TopBarBattery { }
        TopBarClock { 
          Layout.rightMargin: 6
        }
      }
    }
  }
}
