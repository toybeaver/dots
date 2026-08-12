// One cell of the month grid.
//
// Only TODAY gets a glass block. Forty-two of them would be forty-two rims in a
// 400px box — this theme's rim is the loudest thing it owns, and repeating it
// per cell turns a grid into a wall of neon with nothing standing out, which is
// the opposite of what a calendar is for.

import "../../consts"

import Quickshell
import QtQuick

Item {
  id: cell

  property int day: 1

  // False for the leading and trailing days that belong to the neighbouring
  // months. They are still drawn — a first week with four blanks in it stops
  // looking like a week.
  property bool inMonth: true

  property bool isToday: false

  CalendarBlock {
    anchors.fill: parent
    visible: cell.isToday

    // Rim collapsed to cyan. Solid means "this one" everywhere in this shell;
    // the gradient is the resting state.
    edge: Theme.get_color("edge_alt")
    edge2: Theme.get_color("edge_alt")
  }

  Text {
    anchors.centerIn: parent

    text: cell.day
    font.family: "Oswald"
    font.pixelSize: ControlMetrics.px(15)
    font.weight: cell.isToday ? 600 : 500

    color: cell.inMonth || cell.isToday
      ? Theme.get_color("fg")
      : Theme.get_color("muted")

    opacity: cell.isToday ? 1.0 : (cell.inMonth ? 0.88 : 0.5)
  }
}
