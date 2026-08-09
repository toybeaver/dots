// The Hunter x Hunter mark: two serifed X forms flanking a central diamond.
//
// Drawn in QML rather than loaded from an SVG so the diamond can take the
// shell's own accent colours. It was an SVG at first, which forced the whole
// mark to one colour — and flat white does not work for this shape: the diamond
// merges into the strokes and the silhouette turns into a solid blob. That was
// worked around with hairline gaps, which is not how the original reads. The
// original solves it with COLOUR (black strokes, red diamond), so this does the
// same with the theme's magenta-to-cyan pair, and the geometry can go back to
// touching the way it should.
//
// Geometry is authored on the same 120x78 grid the SVG used. The diamond is
// drawn last, so its apex sits over the top and bottom serif bars rather than
// being interrupted by them.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Shapes

Item {
  id: logo

  // Width. Height follows the mark's 120:78 aspect.
  property real size: 32

  property color color: SnekStyles.get_color("fg")

  // Set false for a flat magenta diamond. The gradient is the same pair used by
  // the pill rims and Hyprland's window borders; on a diamond this small it
  // mostly reads as a single warm-to-cool shift rather than two distinct hues.
  property bool gradientDiamond: true

  implicitWidth: logo.size
  implicitHeight: Math.round(logo.size * 78 / 120)

  Item {
    width: 120
    height: 78
    anchors.centerIn: parent
    scale: logo.size / 120

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      // The two X forms. Each stroke is a slanted bar with horizontal ends,
      // which is what lets the serif bars sit flush on them.
      ShapePath {
        fillColor: logo.color
        strokeColor: "transparent"
        PathSvg {
          path: "M8,6   L18,6  L52,72  L42,72  Z
                 M42,6  L52,6  L18,72  L8,72   Z
                 M68,6  L78,6  L112,72 L102,72 Z
                 M102,6 L112,6 L78,72  L68,72  Z"
        }
      }

      // Serif caps. The inner pair runs straight through the centre — no gap,
      // because the diamond no longer needs negative space to be legible.
      ShapePath {
        fillColor: logo.color
        strokeColor: "transparent"
        PathSvg {
          path: "M2,3  L26,3  L26,9  L2,9  Z
                 M34,3 L86,3  L86,9  L34,9 Z
                 M94,3 L118,3 L118,9 L94,9 Z

                 M2,69  L26,69  L26,75  L2,75  Z
                 M34,69 L86,69  L86,75  L34,75 Z
                 M94,69 L118,69 L118,75 L94,75 Z"
        }
      }

      // The diamond, last so it paints over the serif bars it crosses.
      ShapePath {
        strokeColor: "transparent"
        fillColor: logo.gradientDiamond
          ? "transparent"
          : SnekStyles.get_color("glass_edge")

        // Runs along the same 45 degree axis as the pill rims and the Hyprland
        // active border, so the whole system tilts the same way.
        fillGradient: logo.gradientDiamond ? diamondGradient : null

        PathSvg { path: "M60,3 L78,39 L60,75 L42,39 Z" }
      }
    }
  }

  LinearGradient {
    id: diamondGradient
    x1: 42
    y1: 3
    x2: 78
    y2: 75
    GradientStop { position: 0.0; color: SnekStyles.get_color("glass_edge") }
    GradientStop { position: 1.0; color: SnekStyles.get_color("glass_edge_alt") }
  }
}
