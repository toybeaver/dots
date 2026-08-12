// The control center's box, and the two pages inside it.
//
// The panel keeps ONE size across both pages — the box never resizes, only its
// contents slide. That is why the wifi page scrolls its list rather than
// growing: a box that changes shape mid-transition reads as two different
// panels rather than one panel turning a page.

import "../../consts"
import "../../glass"
import "../../shared/state"
import "wifi"

import Quickshell
import QtQuick

Item {
  id: panel

  readonly property int pad: ControlMetrics.px(18)

  // Sized entirely by the main page. MainView.implicitWidth comes from its
  // grid, not from the width assigned back to it, so this does not loop.
  implicitWidth: main.implicitWidth + panel.pad * 2
  implicitHeight: main.implicitHeight + panel.pad * 2

  Rectangle {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    color: Theme.get_color("panel")
  }

  GlassSurface {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    bevel: 5
    fresnel: 0.50
    spec: 0.14
    // Lower than the pills'. The same grain that reads as texture on a 40px
    // pill reads as noise across a surface this size.
    grain: 0.014
  }

  // Swallows clicks that land on the panel body rather than on a control, so
  // the dim's dismiss handler underneath does not fire. Declared before the
  // pages, so they stack above it and keep their own clicks.
  MouseArea { anchors.fill: parent }

  Item {
    id: viewport

    anchors.fill: parent
    anchors.margins: panel.pad
    clip: true

    Row {
      // Both pages are laid out side by side at viewport width; sliding the
      // row is what changes pages. Nothing is destroyed or rebuilt, so the
      // wifi list keeps its scroll position and any half-typed password.
      x: -ControlCenterState.page * viewport.width

      Behavior on x {
        // Off while the panel is hidden, so resetting the page on close snaps
        // instead of animating a slide behind the fade out.
        enabled: ControlCenterState.open
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }

      MainView {
        id: main
        width: viewport.width
        height: viewport.height
      }

      WifiView {
        width: viewport.width
        height: viewport.height
      }
    }
  }
}
