// The neo-brutalist surface: a flat block, a hard border, and a hard offset
// shadow. No gradients, no blur, no antialiased softness anywhere.
//
// The offset shadow is the whole idiom, and it is NOT a shadow in the usual
// sense — it is a second solid rectangle sitting down and to the right, with a
// crisp edge. A blurred shadow implies a light source and soft material, which
// is exactly what this style refuses. Nothing here fades.
//
// Interaction follows from the same idea. A PRESS pushes the block into its own
// shadow rather than lighting it: the body slides down-right by the offset and
// the shadow disappears behind it, so the block reads as physically pushed into
// the page. That is the one animation this theme allows, and it moves in whole
// pixels.
//
// A press, not a hover. Hover drove this once and it was wrong twice over: the
// button lurched at a pointer merely passing across it, and it claimed to be
// pressed when nothing had been.
//
// THE CONTRACT, because `pressed` on its own is not enough. The block and the
// caller's CONTENT have to move together, or the box slides out from under its
// own icon — which is exactly how this behaved at first, and it reads as the
// button coming apart rather than as depth. So the caller writes
//
//     transform: Translate { x: surface.shift; y: surface.shift }
//
// on the item holding both this surface and the content, and this file moves the
// SHADOW backwards by the same amount so it stays where it is on screen. Setting
// `pressed` without that transform leaves the block still and merely retracts
// the shadow, which looks like the depth being switched off.
//
// Same property names as the other themes' surfaces so components copy across
// unchanged. Which ones mean anything:
//
//   base        -> the block's fill
//   edge        -> the border, and the offset shadow
//   borderWidth -> thickness of both
//   offset      -> how far the shadow falls
//   pressed     -> slides the block onto its shadow (needs the caller's
//                  Translate — see THE CONTRACT above)
//   shift       -> how far it is displaced right now; the caller binds its
//                  Translate to this
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

  // How far a held button is displaced right now. PUBLIC because the caller has
  // to move its content by exactly this — see THE CONTRACT in the header.
  property real shift: surface.pressed ? surface.offset : 0

  // Snappy and short. A slow ease would reintroduce exactly the softness the
  // rest of this file removes.
  Behavior on shift { NumberAnimation { duration: 70 } }

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
  //
  // This is the only piece that moves in here, and it moves BACKWARDS — by
  // exactly what the caller's Translate carries the whole tile forwards — so it
  // lands in the same place on screen whether the button is held or not.
  Rectangle {
    x: surface.offset - surface.shift
    y: surface.offset - surface.shift
    width: parent.width
    height: parent.height

    color: surface.shadowColor
    antialiasing: false
  }

  // The block does NOT move relative to its own item. It appears to, because
  // the caller translates the whole thing — surface, content and all.
  Rectangle {
    id: block

    width: parent.width
    height: parent.height

    color: surface.base
    border.color: surface.edge
    border.width: surface.borderWidth

    // Square, deliberately. See the header.
    radius: 0
    antialiasing: false
  }
}
