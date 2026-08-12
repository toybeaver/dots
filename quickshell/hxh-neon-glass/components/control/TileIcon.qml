// The control center's icon set, drawn as vector paths.
//
// No icon font is installed on this machine, and adding one for seven glyphs is
// a heavy dependency for something that then cannot take a theme colour per
// element. Drawing them here keeps stroke weight consistent in one place and
// lets the wifi icon fade individual arcs by signal strength, which a font
// glyph could not do at all.
//
// All geometry is authored on a 24x24 grid and scaled from there, so `size` is
// the only thing a caller needs to set.

import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Shapes

Item {
  id: icon

  // One of: power, restart, logout, speaker, airplane, wifi, bell,
  // chevronRight, chevronLeft, refresh
  property string name: ""

  property real size: 24
  property color color: Theme.get_color("fg")

  // speaker only — draws the cross instead of the waves.
  property bool muted: false

  // wifi only — 0 to 3. Four discrete levels: the bare dot, then one, two or
  // three arcs. Callers map signal strength with NetworkWatcher.bars().
  property int bars: 3
  // wifi and bell — draws the strike-through.
  property bool off: false

  readonly property real stroke: 2

  implicitWidth: icon.size
  implicitHeight: icon.size

  // ShapePath is not an Item, so it has no opacity of its own — dimming an
  // individual arc has to go through the colour's alpha channel.
  function fade(c: color, a: real): color {
    return Qt.rgba(c.r, c.g, c.b, a);
  }

  Item {
    width: 24
    height: 24
    anchors.centerIn: parent
    scale: icon.size / 24

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      // ---- power ----
      // Ring with a gap at the top and a bar through it. The arc is written as
      // an SVG arc rather than PathAngleArc because the sign convention for
      // sweep is unambiguous here: large-arc=1 sweep=0 takes the long way
      // round, through the bottom, leaving the gap where the bar sits.
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "power" ? "M8.2,5.6 A7.5,7.5 0 1 0 15.8,5.6" : "" }
      }
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "power" ? "M12,3 L12,11" : "" }
      }

      // ---- restart ----
      // Three quarters of a circle with a filled head at the open end.
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "restart" ? "M12,4.5 A7.5,7.5 0 1 0 19.5,12" : "" }
      }
      ShapePath {
        fillColor: icon.color
        strokeColor: "transparent"
        PathSvg { path: icon.name === "restart" ? "M11.4,1.4 L16,4.5 L11.4,7.6 Z" : "" }
      }

      // ---- logout ----
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg {
          path: icon.name === "logout"
            ? "M11,4 L6.5,4 A2.5,2.5 0 0 0 4,6.5 L4,17.5 A2.5,2.5 0 0 0 6.5,20 L11,20"
            : ""
        }
      }
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: icon.name === "logout" ? "M10.5,12 L20,12 M16.5,8.5 L20,12 L16.5,15.5" : "" }
      }

      // ---- speaker ----
      ShapePath {
        fillColor: icon.color
        strokeColor: "transparent"
        PathSvg { path: icon.name === "speaker" ? "M3.5,9.5 L7.5,9.5 L12.5,5 L12.5,19 L7.5,14.5 L3.5,14.5 Z" : "" }
      }
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg {
          path: icon.name !== "speaker" ? ""
            : icon.muted ? "M16.5,9.5 L21.5,14.5 M21.5,9.5 L16.5,14.5"
                         : "M15.8,9.2 A4,4 0 0 1 15.8,14.8 M18.6,6.4 A8,8 0 0 1 18.6,17.6"
        }
      }

      // ---- airplane ----
      ShapePath {
        fillColor: icon.color
        strokeColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        PathSvg {
          path: icon.name === "airplane"
            ? "M12,2 A1.4,1.4 0 0 1 13.4,3.4 L13.4,8.8 L21,13.2 L21,15.2 L13.4,12.9 " +
              "L13.4,17.9 L16,19.8 L16,21.4 L12,20.2 L8,21.4 L8,19.8 L10.6,17.9 " +
              "L10.6,12.9 L3,15.2 L3,13.2 L10.6,8.8 L10.6,3.4 A1.4,1.4 0 0 1 12,2 Z"
            : ""
        }
      }

      // ---- chevrons and refresh ----
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg {
          path: icon.name === "chevronRight" ? "M9,5 L16,12 L9,19"
              : icon.name === "chevronLeft"  ? "M15,5 L8,12 L15,19"
              : ""
        }
      }

      // A near-full circle with a head at the open end. Same construction as
      // the restart glyph but lighter, since this one is a plain button.
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "refresh" ? "M12,5 A7,7 0 1 0 19,12" : "" }
      }
      ShapePath {
        fillColor: icon.color
        strokeColor: "transparent"
        PathSvg { path: icon.name === "refresh" ? "M11.6,2.2 L15.8,5 L11.6,7.8 Z" : "" }
      }

      // ---- wifi ----
      // Three arcs struck about a centre below the icon, plus the dot. Each arc
      // lights independently so the icon carries signal strength rather than
      // just connectedness.
      ShapePath {
        strokeColor: icon.fade(icon.color,
          !icon.off && icon.bars >= 3 ? 1.0 : 0.22)
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "wifi" ? "M1.6,13.6 A11.5,11.5 0 0 1 22.4,13.6" : "" }
      }
      ShapePath {
        strokeColor: icon.fade(icon.color,
          !icon.off && icon.bars >= 2 ? 1.0 : 0.22)
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "wifi" ? "M4.8,15.1 A8,8 0 0 1 19.2,15.1" : "" }
      }
      ShapePath {
        strokeColor: icon.fade(icon.color,
          !icon.off && icon.bars >= 1 ? 1.0 : 0.22)
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "wifi" ? "M8.4,16.8 A4,4 0 0 1 15.6,16.8" : "" }
      }
      ShapePath {
        fillColor: icon.fade(icon.color, icon.off ? 0.22 : 1.0)
        strokeColor: "transparent"
        PathSvg {
          path: icon.name === "wifi"
            ? "M12,17.9 A1.6,1.6 0 1 1 11.98,17.9 Z"
            : ""
        }
      }
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "wifi" && icon.off ? "M4,5 L20,20" : "" }
      }

      // ---- bell ----
      // Dome, skirt and clapper, drawn as one outline plus one arc. Stroked
      // rather than filled: at 22px a solid bell reads as a blob, and the
      // silhouette is what makes it legible at that size.
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg {
          path: icon.name === "bell"
            ? "M12,3.4 A5.4,5.4 0 0 1 17.4,8.8 L17.4,13.1 L19.2,16.3 " +
              "L4.8,16.3 L6.6,13.1 L6.6,8.8 A5.4,5.4 0 0 1 12,3.4 Z"
            : ""
        }
      }
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "bell" ? "M9.9,18.4 A2.4,2.4 0 0 0 14.1,18.4" : "" }
      }

      // Silenced. Same strike the wifi icon uses, so "off" looks the same
      // wherever it appears.
      ShapePath {
        strokeColor: icon.color
        strokeWidth: icon.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: icon.name === "bell" && icon.off ? "M4,5 L20,20" : "" }
      }

    }
  }
}
