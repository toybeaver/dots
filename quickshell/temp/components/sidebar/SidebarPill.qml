import "../../consts"
import "../../surface"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: pill

  implicitWidth: 40
  Layout.alignment: Qt.AlignRight

  // Kept as a pair for parity with hxh-neon-glass, where these are the two ends of
  // a rim gradient. This theme's Surface ignores `edgeColorAlt` entirely — it
  // has no gradient — so only the first has any effect here. Alert states set
  // both anyway, so a component can move between themes unchanged.
  property color edgeColor: Theme.get_color("edge")
  property color edgeColorAlt: Theme.get_color("edge_alt")

  // Set false to keep the layout and spacing but drop the surface, leaving the
  // content bare on the wallpaper. The workspace switcher uses this — its dots
  // are already a strong enough shape that a pill around them just adds noise.
  property bool filled: true

  Surface {
    anchors.fill: parent
    visible: pill.filled

    edge: pill.edgeColor
    edge2: pill.edgeColorAlt
  }
}
