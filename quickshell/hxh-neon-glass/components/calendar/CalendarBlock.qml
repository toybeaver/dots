// A glass block inside the calendar — the month title and the today marker.
//
// The same role CalendarBlock plays in the brutalist themes, drawn in this
// theme's material instead: a translucent panel with a neon rim rather than a
// flat block with a hard shadow. Call sites are the same either way, which is
// what lets CalendarPanel and CalendarDay stay recognisably the same files.
//
// State is signalled by COLLAPSING the rim to a single colour, exactly as
// SidebarBattery and the control center's toggles do. A gradient means "at
// rest"; one colour means "this one".

import "../../consts"
import "../../glass"

import Quickshell
import QtQuick

GlassSurface {
  id: block

  // Collapsing the rim means setting BOTH ends to the same colour explicitly.
  // There is no shortcut by comparing against the default — get_color() returns
  // a string and these are colours, so the test is always unequal. See the note
  // in SidebarPill.
  radius: ControlMetrics.px(8)

  // Softer than a sidebar pill's. These are 42px cells inside an already
  // frosted panel, so the pill's full bevel and specular read as a second sheet
  // of glass stacked on the first.
  bevel: 3
  fresnel: 0.55
  spec: 0.14
  grain: 0.018
}
