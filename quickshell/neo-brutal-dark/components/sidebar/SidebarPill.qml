import "../../consts"
import "../../brutal"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: pill

  // 36, not 40: the offset shadow adds 4px to the right and bottom of every
  // pill, and at 40 in a 45px bar that shadow fell off the edge of the surface
  // and was clipped.
  implicitWidth: 46
  Layout.alignment: Qt.AlignHCenter

  // Kept as a pair for parity with hxh-neon-glass, where these are the two ends of
  // a rim gradient. This theme's BrutalSurface ignores `edgeColorAlt` entirely — it
  // has no gradient — so only the first has any effect here. Alert states set
  // both anyway, so a component can move between themes unchanged.
  // The pill's hue. Assigned per pill by the sidebar components; which slot it
  // lands in is decided below, exactly as in ControlTile.
  property color accent: Theme.get_color("neutral")

  property color edgeColor: Theme.get_color("edge")
  property color edgeColorAlt: Theme.get_color("edge_alt")

  // Set false to keep the layout and spacing but drop the surface, leaving the
  // content bare on the wallpaper. The workspace switcher uses this — its dots
  // are already a strong enough shape that a pill around them just adds noise.
  property bool filled: true

  BrutalSurface {
    anchors.fill: parent
    visible: pill.filled

    // Hue in the block, ink on the outline, shadow a darker shade of the hue —
    // see the note in ControlTile.
    base: pill.accent
    edge: Theme.get_color("edge")
    shadowColor: Qt.darker(pill.accent, 2.2)

    borderWidth: ControlMetrics.px(2)
    offset: ControlMetrics.px(4)
  }

}
