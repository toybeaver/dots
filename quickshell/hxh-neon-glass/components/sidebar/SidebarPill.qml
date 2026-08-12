import "../../consts"
import "../../glass"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: pill

  implicitWidth: 40
  Layout.alignment: Qt.AlignRight

  // The two ends of the rim gradient. Alert states set BOTH to the same colour
  // (see SidebarBattery) so the rim collapses to solid — a half-magenta,
  // half-orange warning would read as decoration rather than a warning.
  //
  // Set explicitly rather than derived by comparing edgeColor against the
  // default: get_color() returns a string and these are `color`, so `===`
  // between them is always false and the gradient silently collapsed.
  property color edgeColor: Theme.get_color("edge")
  property color edgeColorAlt: Theme.get_color("edge_alt")

  // Set false to keep the layout and spacing but drop the surface, leaving the
  // content bare on the wallpaper. The workspace switcher uses this — its dots
  // are already a strong enough shape that a pill around them just adds noise.
  property bool filled: true

  GlassSurface {
    anchors.fill: parent
    visible: pill.filled

    edge: pill.edgeColor
    edge2: pill.edgeColorAlt
  }
}
