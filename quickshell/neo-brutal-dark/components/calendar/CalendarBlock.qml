// A coloured block inside the calendar — the month title and the today marker.
//
// One of the two files in components/calendar/ that differ between the
// brutalist twins, and it differs in one line: where the shadow's colour comes
// from. Same seam ControlTile and SidebarPill sit on; see the twin's copy, and
// the README's note on why the shadow rule has to split.

import "../../consts"
import "../../brutal"

import Quickshell
import QtQuick

BrutalSurface {
  id: block

  // The hue. Named `accent` rather than set through `base` directly so the two
  // twins can take it apart differently without the call sites changing.
  property color accent: Theme.get_color("neutral")

  // Hue in the block and ink on the outline, as in the light twin. What cannot
  // carry over is the shadow: an ink shadow on a near-black panel is invisible,
  // so it comes off the block's own hue instead, darkened well clear of the
  // border so the two do not merge into one L-shape.
  base: block.accent
  edge: Theme.get_color("edge")
  shadowColor: Qt.darker(block.accent, 2.2)

  // Lighter than a control tile's. These blocks are 45px cells and a 48px title
  // strip, not 115px tiles; the panel's own border is already px(4), and a
  // second heavy outline inside it flattens the hierarchy.
  borderWidth: ControlMetrics.px(2)
  offset: ControlMetrics.px(3)
}
