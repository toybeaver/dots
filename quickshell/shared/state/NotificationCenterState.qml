// Whether the notification center is open, and which screen shows it.
//
// The same shape as CalendarState, and for the same reasons: non-visual, so it
// is shared; per-screen, so it is a singleton rather than a delegate property.

pragma Singleton

import "../watchers"

import Quickshell
import QtQuick

Singleton {
  id: root

  property bool open: false

  // The ShellScreen whose panel is drawn. Null while closed.
  property var screen: null

  // Distance from the TOP of the sidebar down to the top of the bell pill,
  // reported by the pill itself. The panel lines its own top up with that, the
  // mirror of what the calendar does at the bottom of the bar.
  property real anchorInset: 0

  function toggle(scr) {
    if (root.open && root.screen === scr) {
      root.open = false;
      return;
    }
    ControlCenterState.close();
    CalendarState.close();
    root.screen = scr;
    root.open = true;

    // Reading the list is what marks it read, so this happens on the way in.
    // Refreshed at the same time: everything else here is driven by mako's
    // signal, but opening the panel is the one moment where being a few seconds
    // stale would actually be seen.
    NotificationWatcher.refresh();
    NotificationWatcher.markRead();
  }

  function close() {
    root.open = false;
  }

  // Popups close each other — three full-screen click-catchers on the overlay
  // layer means two of them can end up stranded underneath the third, and the
  // control center answers an IPC handler that reaches it without passing
  // through any of them.
  //
  // The dependencies run one way only: this file knows about the other two,
  // CalendarState knows about the control center, and the control center knows
  // about nobody. Nothing here is a cycle waiting on initialisation order.
  Connections {
    target: ControlCenterState
    function onOpenChanged() {
      if (ControlCenterState.open) root.open = false;
    }
  }

  Connections {
    target: CalendarState
    function onOpenChanged() {
      if (CalendarState.open) root.open = false;
    }
  }
}
