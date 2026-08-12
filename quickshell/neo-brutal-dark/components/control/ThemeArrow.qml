// One of the theme switcher's two arrows.
//
// Its own MouseArea rather than the parent tile's, so the < and > halves stay
// independent and the label between them stays inert.

import "../../consts"
import "../../shared/state"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: arrow

  property string icon: ""

  signal clicked

  Layout.preferredWidth: ControlMetrics.px(34)
  Layout.fillHeight: true

  TileIcon {
    anchors.centerIn: parent
    name: arrow.icon
    size: ControlMetrics.px(20)
    color: Theme.get_color("on_block")
    opacity: ThemeSwitcher.switching ? 0.25 : (hit.containsMouse ? 1.0 : 0.55)
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  MouseArea {
    id: hit
    anchors.fill: parent
    enabled: !ThemeSwitcher.switching
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: arrow.clicked()
  }
}
