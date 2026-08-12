// The flat theme's surface, standing in for hxh-neon-glass's GlassSurface.
//
// Same property names on purpose. Every component in this theme started as a
// copy of the hxh-neon-glass one, and keeping the surface API identical is what
// lets those copies stay diffable against their originals — the interesting
// difference between two themes should be this file, not three hundred lines
// of call sites.
//
// Which properties are honoured and which are accepted-and-ignored is the
// whole theme, stated in one place:
//
//   tint     -> the fill
//   edge     -> the border
//   fresnel  -> border opacity, so hover still lifts the outline
//   radius   -> IGNORED. Corners are a theme decision, not a caller's, and
//               this theme is square. Callers still pass one; it does nothing.
//   edge2    -> IGNORED. There is no gradient here, so the rim cannot collapse
//               from two colours to one. State shows as a brighter edge
//               instead, which is why fresnel carries hover.
//   bevel / spec / grain -> IGNORED. Shader parameters with no flat analogue.

import "../consts"

import Quickshell
import QtQuick

Item {
  id: surface

  property real radius: 0
  property real bevel: 0
  property real fresnel: 0.60
  property real spec: 0
  property real grain: 0

  property color tint: Theme.get_color("surface")
  property color edge: Theme.get_color("edge")
  property color edge2: Theme.get_color("edge_alt")

  Rectangle {
    anchors.fill: parent

    // Square, deliberately. See the header.
    radius: 0

    color: surface.tint

    // A hairline at every scale. The glass theme's rim is a shader gradient
    // that thickens with the surface; this one must not, or the panel would
    // read as a frame around the tiles rather than the same material.
    border.width: 1
    border.color: Qt.rgba(surface.edge.r, surface.edge.g, surface.edge.b,
                          Math.max(0, Math.min(1, surface.fresnel)))
  }
}
