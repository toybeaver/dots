// Shared surface for everything in the control center grid.
//
// Deliberately NOT using a default property alias for content: an alias would
// capture this file's own children too, so the glass and the mouse area would
// end up nested inside the content holder. Subclasses just declare their
// content as ordinary children instead. They land above the MouseArea in the
// stacking order, which is harmless — Text and Shape do not accept mouse
// events, so clicks still fall through to it.

import "../../consts"
import "../../glass"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: tile

  property color edgeColor: SnekStyles.get_color("glass_edge")
  property color edgeColorAlt: SnekStyles.get_color("glass_edge_alt")

  // Set false by tiles that handle their own input, so the two mouse areas do
  // not fight over the same clicks. VolumeTile does this.
  property bool interactive: true

  readonly property bool hovered: mouse.containsMouse

  signal clicked

  Layout.preferredWidth: 72
  Layout.preferredHeight: 72

  GlassSurface {
    anchors.fill: parent

    edge: tile.edgeColor
    edge2: tile.edgeColorAlt

    // Hover lifts the rim rather than washing the whole surface. The rim is the
    // only part of the glass with any colour in it, so it is what reads at a
    // glance without making the tile look pressed.
    fresnel: tile.hovered ? 0.90 : 0.60
    Behavior on fresnel {
      NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: tile.interactive
    hoverEnabled: tile.interactive
    cursorShape: tile.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: tile.clicked()
  }
}
