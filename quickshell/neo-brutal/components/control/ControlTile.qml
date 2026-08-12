// Shared surface for everything in the control center grid.
//
// Deliberately NOT using a default property alias for content: an alias would
// capture this file's own children too, so the surface and the mouse area would
// end up nested inside the content holder. Subclasses just declare their
// content as ordinary children instead. They land above the MouseArea in the
// stacking order, which is harmless — Text and Shape do not accept mouse
// events, so clicks still fall through to it.

import "../../consts"
import "../../brutal"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: tile

  // The tile's hue. Assigned per cell in MainView, identically in both
  // brutalist themes — the light/dark inversion happens below, not there.
  property color accent: Theme.get_color("surface")

  property color edgeColor: Theme.get_color("edge")
  property color edgeColorAlt: Theme.get_color("edge_alt")

  // Set false by tiles that handle their own input, so the two mouse areas do
  // not fight over the same clicks. VolumeTile does this.
  property bool interactive: true

  readonly property bool hovered: mouse.containsMouse

  signal clicked

  Layout.preferredWidth: ControlMetrics.px(72)
  Layout.preferredHeight: ControlMetrics.px(72)

  BrutalSurface {
    anchors.fill: parent

    // LIGHT twin: the hue is the block, the outline is ink.
    base: tile.accent
    edge: tile.edgeColor

    // Hover presses the block into its own shadow. No fade, no glow — the one
    // interaction this style permits is displacement.
    pressed: tile.hovered && tile.interactive
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
