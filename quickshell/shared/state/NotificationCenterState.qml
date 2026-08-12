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
  }

  function close() {
    root.open = false;
  }

  // Hooked to the PROPERTY, not to toggle()/close(). The popups have to be held
  // and released on every path the panel opens and shuts by, and two of those
  // paths are the Connections below — which set `open` directly and never go
  // near either function.
  onOpenChanged: {
    if (root.open) {
      NotificationWatcher.holdPopups();

      // Everything else is driven by mako's signal, but opening the panel is
      // the one moment where being a few seconds stale would be seen.
      NotificationWatcher.refresh();
    } else {
      NotificationWatcher.releasePopups();
    }

    // Marked on the way in AND on the way out. On the way in for what was
    // already waiting; on the way out for anything that arrived while the panel
    // was open, which the user was looking at the whole time.
    NotificationWatcher.markRead();
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
