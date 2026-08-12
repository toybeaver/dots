// Theme switcher: < name >.
//
// The label is this theme's own `Theme.label` rather than anything queried at
// runtime — the running process IS the current theme, so there is nothing to
// look up and nothing that can drift out of sync.
//
// interactive: false because the body does nothing; only the two arrows take
// clicks, each with its own hit area. Same split as the wifi tile's chevron.

import "../../consts"
import "../../shared/state"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  interactive: false

  // Flips to a different hue on the way out. The shell dies moments later, so
  // this is mostly a confirmation that the click registered at all.
  accent: ThemeSwitcher.switching
    ? Theme.get_color("acc_orange")
    : Theme.get_color("acc_lime")

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: ControlMetrics.px(6)
    anchors.rightMargin: ControlMetrics.px(6)
    spacing: 0

    ThemeArrow {
      Layout.alignment: Qt.AlignVCenter
      icon: "chevronLeft"
      onClicked: ThemeSwitcher.prev()
    }

    Text {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter

      text: Theme.label
      horizontalAlignment: Text.AlignHCenter
      font.family: "Adwaita Sans"
      font.pixelSize: ControlMetrics.px(15)
      font.weight: 800
      color: Theme.get_color("on_block")
      opacity: ThemeSwitcher.switching ? 0.45 : 1.0
      Behavior on opacity { NumberAnimation { duration: 120 } }
      elide: Text.ElideRight
    }

    ThemeArrow {
      Layout.alignment: Qt.AlignVCenter
      icon: "chevronRight"
      onClicked: ThemeSwitcher.next()
    }
  }
}
