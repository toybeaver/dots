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
      opacity: ControlCenterState.open ? 0.40 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: ControlCenterState.close()
      }
    }

    ControlPanel {
      anchors.centerIn: parent

      visible: ControlCenterState.screen === win.modelData

      opacity: ControlCenterState.open ? 1.0 : 0.0
      scale: ControlCenterState.open ? 1.0 : 0.96

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }
  }
}
