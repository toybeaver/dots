// Close every popup when the workspace changes.
//
// Switching workspaces is a change of subject. A calendar or a notification
// list left hanging over the workspace you just moved to belongs to the one you
// left, and it sits on the overlay layer with a full-screen click-catcher
// underneath it — so it does not just look stale, it eats the first click you
// make on whatever you switched to.
//
// A Scope instantiated from each theme's shell.qml rather than a singleton:
// nothing would ever read a singleton, and a singleton nothing reads is never
// constructed. Same shape and same reason as ThemeIpc.
//
// Non-visual, so it lives in shared/ and all three themes get it from one file.

import Quickshell
import Quickshell.Hyprland
import QtQuick

Scope {
  id: root

  // The workspace's ID, not the workspace OBJECT. Quickshell hands out live
  // HyprlandWorkspace objects and is free to reuse one, in which case the
  // object identity never changes and a binding on it never fires. The id is
  // the thing that actually means "somewhere else".
  //
  // -1 while Hyprland has not answered yet. The first real value therefore
  // looks like a change and closes the popups, which is harmless: this runs at
  // startup, when nothing is open, and closing something already closed does
  // not even emit a signal.
  readonly property int focusedId: Hyprland.focusedWorkspace
    ? Hyprland.focusedWorkspace.id
    : -1

  onFocusedIdChanged: {
    ControlCenterState.close();
    CalendarState.close();
    NotificationCenterState.close();
  }
}
