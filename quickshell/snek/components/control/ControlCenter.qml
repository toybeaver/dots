// The control center overlay: one of these per screen.
//
// Every screen dims; only the screen that owns the panel draws it. That split is
// why ControlCenterState is a singleton rather than a property on the Variants
// delegate.
//
// No blur layer rule for this surface, deliberately — see the note in
// hyprland.lua where the sidebar's rule used to be. decoration:blur settings
// reach every surface with a rule, and this one dims the screen itself anyway,
// so there is nothing a blur would add.

import "../../state"

import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: win

  required property var modelData
  screen: modelData

  // Width of the sidebar, so the panel can clear it. Passed in rather than
  // hardcoded — this window ignores the exclusive zone, so it has no other way
  // to know where the bar ends.
  required property int barWidth

  // Named so hyprland.lua can target this surface if it ever needs to.
  WlrLayershell.namespace: "snek-control"

  // Overlay so the panel is not buried under a fullscreen window.
  WlrLayershell.layer: WlrLayer.Overlay

  // Dropped back to None on close so the surface never swallows keystrokes
  // while it is invisible.
  WlrLayershell.keyboardFocus: ControlCenterState.open
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

  // Stays mapped while the dim is still fading out. Binding straight to
  // ControlCenterState.open would unmap the surface on the first frame of the
  // close, so the fade would never be seen.
  visible: ControlCenterState.open || dim.opacity > 0.001

  Item {
    anchors.fill: parent

    focus: true
    Keys.onEscapePressed: ControlCenterState.close()

    Rectangle {
      id: dim

      anchors.fill: parent
      color: "#000000"
      opacity: ControlCenterState.open ? 0.55 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: ControlCenterState.close()
      }
    }

    ControlPanel {
      // Sits beside the bar, bottom aligned with it, rather than centred. The
      // bottom margin matches the last pill's Layout.bottomMargin so the panel
      // and the bar end on the same line.
      //
      // The offset has to come from win.barWidth: this surface sets
      // exclusionMode Ignore, so it extends under the bar and parent.left is
      // the screen edge, not the bar's edge.
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.leftMargin: win.barWidth + 10
      anchors.bottomMargin: 10

      visible: ControlCenterState.screen === win.modelData

      opacity: ControlCenterState.open ? 1.0 : 0.0
      scale: ControlCenterState.open ? 1.0 : 0.96

      // Grows out of the corner nearest the button rather than from its middle.
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
