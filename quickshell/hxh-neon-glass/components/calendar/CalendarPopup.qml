// The calendar overlay: one of these per screen.
//
// Structurally the control center's twin — a full-screen surface on the overlay
// layer that draws its panel on one screen only — with one deliberate
// difference: it does NOT dim the desktop. This is a glance widget hanging off
// the date pill, not a modal page, and dimming a whole display to show a 420px
// box reads as far heavier than the thing deserves.
//
// What it does keep is the full-screen click-catcher. That is what dismisses on
// an outside click, and it is also why clicking the date pill a second time
// closes the popup: the catcher is on the overlay layer, above the bar, so the
// second click never reaches the pill at all. Same as the control center's dim.
//
// This surface carries its own blur rule (hxh-neon-glass-calendar-glass in
// hyprland.lua). Having no dim actually makes that rule EASIER than the control
// center's: the catcher is fully transparent and the panel is ~0.80, so the
// ignore_alpha threshold between them has a wide berth rather than the narrow
// gap the dim leaves.

import "../../shared/state"
import "../../consts"

import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: win

  required property var modelData
  screen: modelData

  // Width of the sidebar, so the popup can clear it. Passed in rather than
  // hardcoded — this window ignores the exclusive zone, so it has no other way
  // to know where the bar ends.
  required property int barWidth

  // Named so hyprland.lua can scope layer rules to this theme's calendar alone.
  WlrLayershell.namespace: Theme.calendarLayer

  WlrLayershell.layer: WlrLayer.Overlay

  // Dropped back to None on close so the surface never swallows keystrokes
  // while it is invisible.
  WlrLayershell.keyboardFocus: CalendarState.open
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.None

  // Covers the screen but must not reserve any of it.
  exclusionMode: ExclusionMode.Ignore

  color: "transparent"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // Stays mapped while the panel is still fading out. Binding straight to
  // CalendarState.open would unmap the surface on the first frame of the close,
  // so the fade would never be seen.
  visible: CalendarState.open || panel.opacity > 0.001

  Item {
    anchors.fill: parent

    focus: true
    Keys.onEscapePressed: CalendarState.close()

    // Invisible, and deliberately not a dim — see the header.
    MouseArea {
      anchors.fill: parent
      onClicked: CalendarState.close()
    }

    CalendarPanel {
      id: panel

      // Beside the bar, and bottom aligned with the DATE PILL rather than with
      // the screen — CalendarState.anchorInset is the distance from the bottom
      // of the bar up to the bottom of that pill, measured by SidebarDate.
      //
      // The left offset has to come from win.barWidth: this surface sets
      // exclusionMode Ignore, so it extends under the bar and parent.left is
      // the screen edge, not the bar's edge.
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.leftMargin: win.barWidth + 10
      anchors.bottomMargin: CalendarState.anchorInset

      visible: CalendarState.screen === win.modelData

      opacity: CalendarState.open ? 1.0 : 0.0
      scale: CalendarState.open ? 1.0 : 0.96

      // Grows out of the corner nearest the pill rather than from its middle.
      transformOrigin: Item.BottomLeft

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }
  }
}
