// Whether the control center is open, and which screen shows it.
//
// This is a singleton rather than a property on the Variants delegate because
// the two roles differ per screen: EVERY screen dims, but only one draws the
// panel. A delegate-local property would dim the monitor you clicked on and
// leave the other one bright.

pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  property bool open: false

  // The ShellScreen whose panel is drawn. Null while closed.
  property var screen: null

  // Clicking the button on the screen that already owns the panel closes it;
  // clicking it on the other screen moves the panel across rather than closing.
  function toggle(scr) {
    if (root.open && root.screen === scr) {
      root.open = false;
    } else {
      root.screen = scr;
      root.open = true;
    }
  }

  function close() {
    root.open = false;
  }
}
