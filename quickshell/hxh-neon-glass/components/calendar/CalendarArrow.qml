// One of the month stepper's two arrows.
//
// Its own MouseArea, the same split ThemeArrow uses: the two halves step in
// opposite directions and the title between them is inert.

import "../../consts"
import "../control"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: arrow

  property string icon: ""

  signal clicked

  Layout.preferredWidth: ControlMetrics.px(28)
  Layout.fillHeight: true

  TileIcon {
    anchors.centerIn: parent
    name: arrow.icon
    size: ControlMetrics.px(18)
    color: Theme.get_color("fg")

    opacity: hit.containsMouse ? 1.0 : 0.55
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  MouseArea {
    id: hit
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: arrow.clicked()
  }
}
