// The neo-brutalist surface: a flat block, a hard border, and a hard offset
// shadow. No gradients, no blur, no antialiased softness anywhere.
//
// The offset shadow is the whole idiom, and it is NOT a shadow in the usual
// sense — it is a second solid rectangle sitting down and to the right, with a
// crisp edge. A blurred shadow implies a light source and soft material, which
// is exactly what this style refuses. Nothing here fades.
//
// Interaction follows from the same idea. Hovering PRESSES the block into its
// own shadow rather than lighting it: the body slides down-right by the offset
// and the shadow disappears behind it, so the block reads as physically pushed
// into the page. That is the one animation this theme allows, and it moves in
// whole pixels.
//
// Same property names as the other themes' surfaces so components copy across
// unchanged. Which ones mean anything:
//
//   base        -> the block's fill
//   edge        -> the border, and the offset shadow
//   borderWidth -> thickness of both
//   offset      -> how far the shadow falls
//   pressed     -> slides the block onto its shadow
//   radius      -> IGNORED. Brutalism is square; corners are a theme decision.
//   edge2 / fresnel / bevel / spec / grain / tint -> IGNORED, see the others.

import "../consts"

import Quickshell
import QtQuick

Item {
  id: surface

  property color base: Theme.get_color("surface")

  // Border and shadow are ONE colour on purpose. They are the same gesture —
  // the hard outline of the block — seen from two sides. Splitting them is what
  // makes a brutalist layout start looking like a sticker.
  property color edge: Theme.get_color("edge")

  // Normally the shadow IS the border colour, per the note above. The dark twin
  // breaks that for one surface: the control panel is the largest object on
  // screen, and an off-white slab at that size is the brightest thing in the
  // whole desktop — a lamp, on a theme built to avoid one. Its border stays
  // bright; only its shadow goes dim.
  property color shadowColor: surface.edge

  property real borderWidth: ControlMetrics.px(3)
  property real offset: ControlMetrics.px(5)

  property bool pressed: false

  // Accepted and ignored, so components lift unchanged from the other themes.
  property real radius: 0
  property color edge2: Theme.get_color("edge_alt")
  property real fresnel: 0
  property real bevel: 0
  property real spec: 0
  property real grain: 0
  property color tint: Theme.get_color("surface")

  // GEOMETRY, and it is worth being precise about because getting it wrong
  // knocks every centred thing in the shell off by half the shadow.
  //
  // The BLOCK fills the item exactly, and the shadow OVERFLOWS bottom-right.
  // The obvious alternative — keeping both inside the item by shrinking the
  // block — puts the block's centre offset/2 up and left of the item's centre,
  // while icons, sliders and labels all centre on the item. Everything then
  // sits low and to the right, uniformly, which reads as sloppy rather than as
  // a geometry bug.
  //
  // The cost is that callers must leave `offset` of room bottom-right, or a
  // clipping ancestor will cut the shadow off. MainView does this explicitly.

  // The hard shadow. Drawn first, so the body covers it when pressed.
  Rectangle {
    x: surface.offset
    y: surface.offset
    width: parent.width
    height: parent.height

    color: surface.shadowColor
    antialiasing: false
  }

  Rectangle {
    id: block

    x: surface.pressed ? surface.offset : 0
    y: surface.pressed ? surface.offset : 0
    width: parent.width
    height: parent.height

    color: surface.base
    border.color: surface.edge
    border.width: surface.borderWidth

    // Square, deliberately. See the header.
    radius: 0
    antialiasing: false

    // Snappy and short. A slow ease would reintroduce exactly the softness the
    // rest of this file removes.
    Behavior on x { NumberAnimation { duration: 70 } }
    Behavior on y { NumberAnimation { duration: 70 } }
  }
}
