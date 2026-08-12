// The control center's landing page: a 3-row by 5-column grid.
//
// Coordinates in the comments are [row:col], 1-indexed, matching the design.
// Layout.row / Layout.column are 0-indexed, hence the offset.
//
// Split out of ControlPanel when the wifi page arrived — that file now only
// holds the two pages and slides between them.

import "../../consts"
import "../../shared/state"
import "../../shared/watchers"

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
  id: view

  // Drives the panel's own size. Taken from the grid rather than from `width`,
  // which the panel assigns back to this item — reading `width` here would be
  // a binding loop.
  // Room for the shadows of the bottom and right-most tiles. BrutalSurface
  // overflows its item by `offset` on those two sides, and the panel's viewport
  // clips, so without this the outer tiles lose their shadow entirely.
  readonly property int shadowRoom: ControlMetrics.px(5)

  implicitWidth: grid.implicitWidth + view.shadowRoom
  implicitHeight: grid.implicitHeight + view.shadowRoom

  // Which power action is armed, or "" for none. Held here rather than on the
  // tiles so arming one disarms the others — otherwise you could leave power
  // armed, click restart, and have two live triggers on screen at once.
  property string armed: ""

  function fire(action: string, command: string) {
    if (view.armed === action) {
      view.armed = "";
      disarmTimer.stop();
      runner.command = ["sh", "-c", command];
      runner.running = true;
    } else {
      view.armed = action;
      disarmTimer.restart();
    }
  }

  // Same 3s window as the MOD+SHIFT+Q bind in hyprland.lua.
  Timer {
    id: disarmTimer
    interval: 3000
    onTriggered: view.armed = ""
  }

  Process { id: runner }

  // Closing the panel must not leave an action armed and waiting for the next
  // time it opens.
  Connections {
    target: ControlCenterState
    function onOpenChanged() {
      if (!ControlCenterState.open) {
        view.armed = "";
        disarmTimer.stop();
      }
    }
  }

  GridLayout {
    id: grid

    anchors.fill: parent
    anchors.rightMargin: view.shadowRoom
    anchors.bottomMargin: view.shadowRoom

    rows: 3
    columns: 5
    rowSpacing: ControlMetrics.px(10)
    columnSpacing: ControlMetrics.px(10)

    // ---- [1:1] [2:1] [3:1] ----
    // One hue per role, assigned here and identically in both brutalist
    // themes. Which slot it lands in — block or outline — is decided in
    // ControlTile, so this file never has to know which twin it is in.
    PowerTile {
      Layout.row: 0
      Layout.column: 0
      icon: "power"
      accent: Theme.get_color("acc_pink")
      armed: view.armed === "poweroff"
      onClicked: view.fire("poweroff", "systemctl poweroff")
    }

    PowerTile {
      Layout.row: 1
      Layout.column: 0
      icon: "restart"
      accent: Theme.get_color("acc_orange")
      armed: view.armed === "reboot"
      onClicked: view.fire("reboot", "systemctl reboot")
    }

    PowerTile {
      Layout.row: 2
      Layout.column: 0
      icon: "logout"
      accent: Theme.get_color("acc_violet")
      armed: view.armed === "exit"
      // Copied verbatim from hyprland.lua so both routes out of the session
      // behave identically.
      onClicked: view.fire("exit",
        "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
    }

    // ---- [1-3:2] ----
    VolumeTile {
      accent: Theme.get_color("acc_cyan")
      Layout.row: 0
      Layout.column: 1
      Layout.rowSpan: 3
      Layout.preferredWidth: ControlMetrics.px(56)
      Layout.fillHeight: true
    }

    // ---- [1:3-5] ----
    WifiTile {
      accent: Theme.get_color("acc_yellow")
      Layout.row: 0
      Layout.column: 2
      Layout.columnSpan: 3
      Layout.fillWidth: true
    }

    // ---- [2:3-5] ----
    ThemeTile {
      accent: Theme.get_color("acc_lime")
      Layout.row: 1
      Layout.column: 2
      Layout.columnSpan: 3
      Layout.fillWidth: true
    }

    // ---- [3:3] and [3:5] ----
    ToggleTile {
      Layout.row: 2
      Layout.column: 2
      icon: "speaker"
      accent: Theme.get_color("acc_pink")
      active: AudioWatcher.muted
      onClicked: AudioWatcher.toggleMute()
    }

    ToggleTile {
      Layout.row: 2
      Layout.column: 4
      icon: "airplane"
      accent: Theme.get_color("acc_cyan")
      active: NetworkWatcher.airplane
      onClicked: NetworkWatcher.setAirplane(!NetworkWatcher.airplane)
    }

    // ---- reserved: [3:4] ----
    //
    // Load-bearing, not filler. GridLayout derives a column's width only from
    // items that do NOT span it, and with both the wifi tile and the theme
    // switcher spanning columns 3-5, this is the only thing left holding
    // column 4 open. Without it mute would slide up against airplane.
    //
    // It is also exactly where the next tile goes — replace it with a real
    // component and the grid absorbs it.
    Item { Layout.row: 2; Layout.column: 3; Layout.preferredWidth: ControlMetrics.px(72); Layout.preferredHeight: ControlMetrics.px(72) }
  }
}
