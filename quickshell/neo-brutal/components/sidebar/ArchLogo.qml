// The Arch Linux mark, simplified: a plain arrowhead with a rounded slot.
//
// Replaces the Hunter x Hunter logo the other themes use on the control button.
// That mark is personal iconography and reads as one; this theme wanted
// something belonging to the machine instead.
//
// SIMPLIFIED ON PURPOSE. The real logo has swept flanks and notched feet, and
// earlier passes here reproduced them — first with the notch apex too high,
// which starved both legs and gave a spindly letter A, then with the feet
// kinked inward. Both failed for the same reason: the mark renders at 26px, and
// every one of those details is two pixels or less. They do not read as
// character at that size, they read as noise on the edges.
//
// What survives is the silhouette. So: clean triangle, no side cuts, and one
// rounded slot for the negative space.
//
// Authored on a 120x120 grid and scaled from there, so `size` is the only thing
// a caller needs to set.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Shapes

Item {
  id: logo

  // Width. The mark is square, so height follows 1:1.
  property real size: 26

  property color color: "#ffffff"

  implicitWidth: logo.size
  implicitHeight: logo.size

  Item {
    width: 120
    height: 120
    anchors.centerIn: parent
    scale: logo.size / 120

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: logo.color
        strokeColor: "transparent"

        // ODD-EVEN, not the default winding rule. The slot is a second subpath
        // inside the first, and under nonzero winding it punches a hole only if
        // it happens to be wound the opposite way — which is exactly the trap
        // that once rendered HxhLogo inside out. Odd-even makes the hole
        // independent of direction.
        fillRule: ShapePath.OddEvenFill

        // The arrowhead, then the slot: straight sides up to y=80, capped by a
        // half circle of radius 12 so the negative space is rounded rather than
        // a sharp V. Open at the bottom, as the real mark's notch is.
        PathSvg {
          path: "M60,10 L112,112 L8,112 Z
                 M48,112 L48,80 A12,12 0 0 1 72,80 L72,112 Z"
        }
      }
    }
  }
}
