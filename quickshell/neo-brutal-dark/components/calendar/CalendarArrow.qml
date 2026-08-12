// One of the month stepper's two arrows.
//
// Its own MouseArea, the same split ThemeArrow uses: the two halves step in
// opposite directions and the title between them is inert.
//
// Bare icon rather than a block. The title strip beside it is already a block
// with a border and a shadow, and flanking it with two more turns a header into
// a row of three competing objects.

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

    // `fg`, not `on_block` — this sits on the panel, not on a coloured block.
    // The two are the same value in the light twin and opposites in the dark
    // one, which is the whole reason the palette carries both.
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
