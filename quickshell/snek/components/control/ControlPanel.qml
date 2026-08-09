// The control center's 3-row by 5-column grid.
//
// Coordinates in the comments are [row:col], 1-indexed, matching the design.
// Layout.row / Layout.column are 0-indexed, hence the offset.

import "../../consts"
import "../../glass"
import "../../state"
import "../../watchers"

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
  id: panel

  readonly property int pad: ControlMetrics.px(18)

  implicitWidth: grid.implicitWidth + panel.pad * 2
  implicitHeight: grid.implicitHeight + panel.pad * 2

  // Which power action is armed, or "" for none. Held here rather than on the
  // tiles so arming one disarms the others — otherwise you could leave power
  // armed, click restart, and have two live triggers on screen at once.
  property string armed: ""

  function fire(action: string, command: string) {
    if (panel.armed === action) {
      panel.armed = "";
      disarmTimer.stop();
      runner.command = ["sh", "-c", command];
      runner.running = true;
    } else {
      panel.armed = action;
      disarmTimer.restart();
    }
  }

  // Same 3s window as the MOD+SHIFT+Q bind in hyprland.lua.
  Timer {
    id: disarmTimer
    interval: 3000
    onTriggered: panel.armed = ""
  }

  Process { id: runner }

  // Closing the panel must not leave an action armed and waiting for the next
  // time it opens.
  Connections {
    target: ControlCenterState
    function onOpenChanged() {
      if (!ControlCenterState.open) {
        panel.armed = "";
        disarmTimer.stop();
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    color: SnekStyles.get_color("panel")
  }

  GlassSurface {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    bevel: 5
    fresnel: 0.50
    spec: 0.14
    // Lower than the pills'. The same grain that reads as texture on a 40px
    // pill reads as noise across a surface this size.
    grain: 0.014
  }

  // Swallows clicks that land on the panel body rather than on a tile, so the
  // dim's dismiss handler underneath does not fire. Declared before the grid,
  // so tiles stack above it and keep their own clicks.
  MouseArea { anchors.fill: parent }

  GridLayout {
    id: grid

    anchors.fill: parent
    anchors.margins: panel.pad

    rows: 3
    columns: 5
    rowSpacing: ControlMetrics.px(10)
    columnSpacing: ControlMetrics.px(10)

    // ---- [1:1] [2:1] [3:1] ----
    PowerTile {
      Layout.row: 0
      Layout.column: 0
      icon: "power"
      label: "power"
      armed: panel.armed === "poweroff"
      onClicked: panel.fire("poweroff", "systemctl poweroff")
    }

    PowerTile {
      Layout.row: 1
      Layout.column: 0
      icon: "restart"
      label: "restart"
      armed: panel.armed === "reboot"
      onClicked: panel.fire("reboot", "systemctl reboot")
    }

    PowerTile {
      Layout.row: 2
      Layout.column: 0
      icon: "logout"
      label: "log out"
      armed: panel.armed === "exit"
      // Copied verbatim from hyprland.lua so both routes out of the session
      // behave identically.
      onClicked: panel.fire("exit",
        "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
    }

    // ---- [1-3:2] ----
    VolumeTile {
      Layout.row: 0
      Layout.column: 1
      Layout.rowSpan: 3
      Layout.preferredWidth: ControlMetrics.px(56)
      Layout.fillHeight: true
    }

    // ---- [1:3-5] ----
    WifiTile {
      Layout.row: 0
      Layout.column: 2
      Layout.columnSpan: 3
      Layout.fillWidth: true
    }

    // ---- [3:3] and [3:5] ----
    ToggleTile {
      Layout.row: 2
      Layout.column: 2
      icon: "speaker"
      label: "mute"
      active: AudioWatcher.muted
      onClicked: AudioWatcher.toggleMute()
    }

    ToggleTile {
      Layout.row: 2
      Layout.column: 4
      icon: "airplane"
      label: "airplane"
      active: NetworkWatcher.airplane
      onClicked: NetworkWatcher.setAirplane(!NetworkWatcher.airplane)
    }

    // ---- reserved: [2:3] [2:4] [2:5] [3:4] ----
    //
    // These are load-bearing, not filler. GridLayout derives a column's width
    // only from items that do NOT span it, so with the wifi tile spanning
    // columns 3-5 and nothing else occupying column 4, that column would
    // collapse to zero and mute would slide up against airplane.
    //
    // They are also exactly where the next tiles go — replace one with a real
    // component and the grid absorbs it.
    Item { Layout.row: 1; Layout.column: 2; Layout.preferredWidth: ControlMetrics.px(72); Layout.preferredHeight: ControlMetrics.px(72) }
    Item { Layout.row: 1; Layout.column: 3; Layout.preferredWidth: ControlMetrics.px(72); Layout.preferredHeight: ControlMetrics.px(72) }
    Item { Layout.row: 1; Layout.column: 4; Layout.preferredWidth: ControlMetrics.px(72); Layout.preferredHeight: ControlMetrics.px(72) }
    Item { Layout.row: 2; Layout.column: 3; Layout.preferredWidth: ControlMetrics.px(72); Layout.preferredHeight: ControlMetrics.px(72) }
  }
}
