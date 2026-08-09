// Lets things outside the shell drive the control center:
//
//   quickshell -c snek ipc call control toggle
//
// which is how the Copilot key opens it — see the SHIFT+F23 bind in
// hyprland.lua. A keybind cannot reach ControlCenterState any other way.
//
// Instantiated once from shell.qml, NOT per screen: there is a single handler
// and it resolves the screen itself.
//
// The screen lookup lives on this outer Scope rather than on the IpcHandler,
// which is not cosmetic. IpcHandler publishes everything declared on it:
//   * a helper written as a function shows up in `ipc show` as a callable
//     method — an untyped one was listed as `focusedScreen(): void`;
//   * a helper written as a property is marshalled too, and a `var` fails with
//     "Type QVariant cannot be used across IPC".
// Keeping it out here leaves the IPC surface as exactly the three actions.

import "../../state"

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
  id: root

  // Re-reads itself as focus moves between monitors.
  readonly property var focusedScreen: {
    const mon = Hyprland.focusedMonitor;
    if (mon) {
      for (const screen of Quickshell.screens) {
        if (screen.name === mon.name) return screen;
      }
    }
    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
  }

  IpcHandler {
    target: "control"

    // Opens on the monitor that currently has focus, so on a two screen setup
    // it appears where you are rather than always on the built in panel.
    function toggle(): void {
      ControlCenterState.toggle(root.focusedScreen);
    }

    function open(): void {
      ControlCenterState.screen = root.focusedScreen;
      ControlCenterState.open = true;
    }

    function close(): void {
      ControlCenterState.close();
    }
  }
}
