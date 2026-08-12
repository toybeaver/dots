// One cell of the month grid.
//
// Only TODAY gets a block. Forty-two blocks in a 420px box would be forty-two
// hard shadows, which stops reading as structure and starts reading as static —
// and it would leave the one date you actually came here to find with nothing
// to distinguish it. Every other day is a bare numeral.
//
// The block fills the cell exactly and its shadow overflows into the grid's
// gutter, which is why the gutter is `gap` and the shadow is smaller than it.
// See BrutalSurface's header for why the block must not be shrunk instead.

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

    // Pink, against the yellow of the title strip and of the date pill this
    // popup hangs off. Today is the one thing in the grid worth a second
    // colour, so it gets the loudest one that is not already spoken for.
    accent: Theme.get_color("acc_pink")
  }

  Text {
    anchors.centerIn: parent

    text: cell.day
    font.family: "Adwaita Sans"
    font.pixelSize: ControlMetrics.px(15)
    font.weight: cell.isToday ? 800 : 700

    // Ink on the block for today; panel text for everything else.
    color: cell.isToday ? Theme.get_color("on_block") : Theme.get_color("fg")

    // Dimmed rather than a separate colour: the neighbouring months are the
    // same kind of thing as this month, just not the subject.
    opacity: cell.inMonth || cell.isToday ? 1.0 : 0.28
  }
}
