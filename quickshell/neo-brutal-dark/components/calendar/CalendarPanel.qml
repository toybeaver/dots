// The calendar's box: a month stepper, a row of weekday headings, and the grid.
//
// Sized EXPLICITLY from the cell geometry rather than from the children's
// implicit sizes. The grid is a fixed 6x7 of fixed cells, so there is nothing
// to discover by measuring — and an implicit chain here would have to run
// through a Repeater over a JS array, which resizes for a frame every time the
// month changes. A popup that is bottom-anchored to the date pill grows upward,
// so a one-frame resize is a visible twitch of the whole box.

import "../../consts"
import "../../brutal"
import "../../shared/state"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: panel

  readonly property int pad: ControlMetrics.px(16)

  // The gutter between cells, and the room a today block's shadow falls into.
  // MUST stay larger than CalendarBlock's `offset` or the marker's shadow lands
  // under the next day's numeral.
  readonly property int gap: ControlMetrics.px(4)

  readonly property int cellW: ControlMetrics.px(30)
  readonly property int cellH: ControlMetrics.px(26)

  readonly property int headerH: ControlMetrics.px(30)
  readonly property int weekdayH: ControlMetrics.px(18)
  readonly property int sectionGap: ControlMetrics.px(8)

  readonly property int gridW: panel.cellW * 7 + panel.gap * 6
  readonly property int gridH: panel.cellH * 6 + panel.gap * 5

  implicitWidth: panel.gridW + panel.pad * 2
  implicitHeight: panel.pad * 2 + panel.headerH + panel.weekdayH + panel.gridH
    + panel.sectionGap * 2

  // The same slab the control center uses, at the same weights, so the two
  // popups read as the same kind of object hanging off the same bar.
  BrutalSurface {
    anchors.fill: parent
    base: Theme.get_color("panel")

    // Light border, not ink, and a dim neutral shadow — the panel is the one
    // surface with no hue to derive a shadow from, and it floats on the bare
    // desktop where ink cannot be seen. Same values its control center uses.
    edge: Theme.get_color("fg")
    shadowColor: "#1a1a1e"

    borderWidth: ControlMetrics.px(4)
    offset: ControlMetrics.px(8)
  }

  // Swallows clicks that land on the panel rather than on a control, so the
  // popup's dismiss handler underneath does not fire. Declared before the
  // content, so the content stacks above it and keeps its own clicks.
  MouseArea { anchors.fill: parent }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: panel.pad
    spacing: panel.sectionGap

    // ---- month stepper ----------------------------------------------------
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: panel.headerH
      spacing: panel.gap

      CalendarArrow {
        icon: "chevronLeft"
        onClicked: CalendarState.step(-1)
      }

      Item {
        id: title

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Label moves with the block — see THE CONTRACT in BrutalSurface.
        transform: Translate { x: titleBlock.shift; y: titleBlock.shift }

        CalendarBlock {
          id: titleBlock

          anchors.fill: parent

          // Yellow, matching the date pill this popup hangs off — the header is
          // the part that says which pill opened it.
          accent: Theme.get_color("acc_yellow")

          // Presses into its own shadow while held, but only while there is
          // somewhere to go back to. A control that animates and then does
          // nothing is worse than one that does not animate.
          pressed: home.pressed && !CalendarState.onToday
        }

        Text {
          anchors.centerIn: parent

          text: CalendarState.monthLabel.toUpperCase() + " " + CalendarState.viewYear
          font.family: "Adwaita Sans"
          font.pixelSize: ControlMetrics.px(14)
          font.weight: 800
          color: Theme.get_color("on_block")
          elide: Text.ElideRight
        }

        // Clicking the month name goes back to today. Undiscoverable on its
        // own, which is why it is free rather than load-bearing: paging back
        // month by month always works, this is just shorter.
        MouseArea {
          id: home
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: CalendarState.onToday ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: CalendarState.showToday()
        }
      }

      CalendarArrow {
        icon: "chevronRight"
        onClicked: CalendarState.step(1)
      }
    }

    // ---- weekday headings -------------------------------------------------
    Row {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: panel.weekdayH
      spacing: panel.gap

      Repeater {
        model: CalendarState.weekdayLabels

        Text {
          required property string modelData

          width: panel.cellW
          height: panel.weekdayH

          text: modelData.toUpperCase()
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter

          font.family: "Adwaita Sans"
          font.pixelSize: ControlMetrics.px(10)
          font.weight: 800
          color: Theme.get_color("muted")
        }
      }
    }

    // ---- the month --------------------------------------------------------
    Grid {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: panel.gridH

      columns: 7
      spacing: panel.gap

      Repeater {
        model: CalendarState.cells

        CalendarDay {
          required property var modelData

          width: panel.cellW
          height: panel.cellH

          day: modelData.day
          inMonth: modelData.inMonth
          isToday: modelData.isToday
        }
      }
    }
  }
}
