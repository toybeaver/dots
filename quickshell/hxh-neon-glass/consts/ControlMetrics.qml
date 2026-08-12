// One knob for the control center's size.
//
// Every dimension in the panel — tile sizes, padding, gaps, corner radii, icon
// sizes and font sizes — goes through px(), so the whole thing scales as a unit
// and stays in proportion. Change `factor` and nothing else.
//
// The numbers passed to px() are the design sizes at 1.0, so they stay readable
// at the call site: px(72) is still recognisably "a 72 unit tile". Resist
// replacing them with named constants here — the point is that a reader of
// ControlPanel.qml can see the real geometry without a second lookup.

pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  // Bumped from 1.0 because the panel read as far too small on a 1920x1200
  // display. At 1.6 the panel is roughly 670x435.
  property real factor: 1.6

  function px(v: real): int {
    return Math.round(v * root.factor);
  }
}
