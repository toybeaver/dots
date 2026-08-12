// The notification center overlay: one of these per screen.
//
// The calendar's mirror image. Same construction — a full-screen surface on the
// overlay layer, no dim, a click-catcher to dismiss — but anchored to the TOP
// of the bar, because the bell pill it hangs off is the first thing in the
// column rather than the last.

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

  // Named so hyprland.lua can scope layer rules to this theme's center alone.
  WlrLayershell.namespace: Theme.notificationLayer

  WlrLayershell.layer: WlrLayer.Overlay

  // OnDemand, NOT Exclusive, and this is load-bearing rather than a preference.
  //
  // An exclusive-focus layer surface takes the keyboard away from the focused
  // WINDOW. When it unmaps, Hyprland hands focus back to that window — and
  // focusing a window that lives on another workspace switches to it. So with a
  // popup open, changing workspace went: switch, popup closes on the workspace
  // change, Hyprland restores the old window, and the workspace snaps straight
  // back. The desktop simply refused to leave the workspace you were on.
  //
  // OnDemand does not take focus off the window, so there is nothing to restore
  // and nothing to snap back to.
  //
  // Escape still works: verified by sending one through hl.dsp.send_shortcut and
  // watching the dim lift. That it reached a Keys handler INSIDE the surface is
  // also what says text entry is unaffected — key events are being delivered to
  // this surface, which is the same path the wifi password field reads from.
  //
  // Dropped back to None on close so the surface never swallows keystrokes
  // while it is invisible.
  WlrLayershell.keyboardFocus: NotificationCenterState.open
    ? WlrKeyboardFocus.OnDemand
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
  // NotificationCenterState.open would unmap the surface on the first frame of
  // the close, so the fade would never be seen.
  visible: NotificationCenterState.open || panel.opacity > 0.001

  Item {
    anchors.fill: parent

    focus: true
    Keys.onEscapePressed: NotificationCenterState.close()

    MouseArea {
      anchors.fill: parent
      onClicked: NotificationCenterState.close()
    }

    NotificationPanel {
      id: panel

      // Beside the bar, top aligned with the BELL PILL —
      // NotificationCenterState.anchorInset is the distance from the top of the
      // bar down to the top of that pill.
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: win.barWidth + 10
      anchors.topMargin: NotificationCenterState.anchorInset

      visible: NotificationCenterState.screen === win.modelData

      opacity: NotificationCenterState.open ? 1.0 : 0.0
      scale: NotificationCenterState.open ? 1.0 : 0.96

      // Grows out of the corner nearest the pill.
      transformOrigin: Item.TopLeft

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }
  }
}
