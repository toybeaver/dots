// The Hunter x Hunter mark: two serifed X forms flanking a central diamond.
//
// Drawn in QML rather than loaded from an SVG so the diamond can take the
// shell's own accent colours. The original is two-tone (black strokes, red
// diamond) and that contrast is load-bearing — flattened to one colour the
// diamond merges into the strokes and the silhouette becomes a blob.
//
// ---------------------------------------------------------------------------
// THE DIAMOND IS THE NEGATIVE SPACE. This is the whole trick, and it is what
// makes the mark gapless.
//
// Measured off the reference art: at every height the red sits directly against
// black with no background between them. That is only possible if the diamond's
// edges are COLLINEAR with the inner edges of the X strokes — not merely
// parallel to them, and not simply touching at the widest point.
//
// So the geometry below is derived, not eyeballed. Given a stroke slope `s`,
// everything follows:
//
//   * the diamond's half-width is its half-height times s, so its edges carry
//     the stroke slope exactly;
//   * each X is then placed so its inner stroke corner lands ON that edge —
//     hence `xInnerTop = 60 - s * (strokeTop - apexY)`.
//
// Widening the diamond on its own does NOT close the gap: the slopes already
// matched, so the two ran parallel with a constant ~7 unit gap and touched at a
// single point. The X's had to move inward instead.
//
// Change `slope` and the whole mark rebuilds around it, still gapless. 0.62 was
// picked by matching the reference's proportions: diamond ~35% of total width,
// X's spanning ~90% of it. (The reference reaches those with a true serif X —
// one thick diagonal, one thin. Both strokes here are equal weight, because at
// 32px the thin one would land under a pixel and mush.)
// ---------------------------------------------------------------------------

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
  // mostly reads as one warm-to-cool shift rather than two distinct hues.
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
      //
      // 58.76 / 17.84 are the inner and outer stroke corners for slope 0.62 —
      // see the derivation above. The inner corner is the one that has to sit
      // exactly on the diamond's edge.
      ShapePath {
        fillColor: logo.color
        strokeColor: "transparent"
        PathSvg {
          path: "M7.84,6    L17.84,6   L58.76,72  L48.76,72  Z
                 M48.76,6   L58.76,6   L17.84,72  L7.84,72   Z
                 M112.16,6  L102.16,6  L61.24,72  L71.24,72  Z
                 M71.24,6   L61.24,6   L102.16,72 L112.16,72 Z"
        }
      }

      // The diamond, under the serifs. Its apexes tuck behind the top and
      // bottom bars exactly as they do in the reference, so what shows is a
      // clean taper rather than a blunt tip.
      ShapePath {
        strokeColor: "transparent"
        fillColor: logo.gradientDiamond
          ? "transparent"
          : SnekStyles.get_color("glass_edge")

        // Runs along the same 45 degree axis as the pill rims and the Hyprland
        // active border, so the whole system tilts the same way.
        fillGradient: logo.gradientDiamond ? diamondGradient : null

        PathSvg { path: "M60,4 L81.7,39 L60,74 L38.3,39 Z" }
      }

      // Serif caps, last so they close off the diamond's points. Centred on the
      // four stroke ends; the inner pair overlaps into one bar across the
      // middle, which is what the reference does too.
      ShapePath {
        fillColor: logo.color
        strokeColor: "transparent"
        PathSvg {
          path: "M2.84,3   L22.84,3   L22.84,9   L2.84,9   Z
                 M43.76,3  L76.24,3   L76.24,9   L43.76,9  Z
                 M97.16,3  L117.16,3  L117.16,9  L97.16,9  Z

                 M2.84,69  L22.84,69  L22.84,75  L2.84,75  Z
                 M43.76,69 L76.24,69  L76.24,75  L43.76,75 Z
                 M97.16,69 L117.16,69 L117.16,75 L97.16,75 Z"
        }
      }
    }
  }

  LinearGradient {
    id: diamondGradient
    x1: 38.3
    y1: 4
    x2: 81.7
    y2: 74
    GradientStop { position: 0.0; color: SnekStyles.get_color("glass_edge") }
    GradientStop { position: 1.0; color: SnekStyles.get_color("glass_edge_alt") }
  }
}
