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

  // LIGHT twin: hue in the block, outline is ink, and the shadow is that same
  // ink — BrutalSurface's default.
  base: block.accent
  edge: Theme.get_color("edge")

  // Lighter than a control tile's. These blocks are 45px cells and a 48px title
  // strip, not 115px tiles; the panel's own border is already px(4), and a
  // second heavy outline inside it flattens the hierarchy.
  borderWidth: ControlMetrics.px(2)
  offset: ControlMetrics.px(3)
}
