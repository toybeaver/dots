// The calendar's box: a month stepper, a row of weekday headings, and the grid.
//
// Sized EXPLICITLY from the cell geometry rather than from the children's
// implicit sizes. The grid is a fixed 6x7 of fixed cells, so there is nothing
// to discover by measuring — and an implicit chain here would have to run
// through a Repeater over a JS array, which resizes for a frame every time the
// month changes. A popup that is bottom-anchored to the date pill grows upward,
// so a one-frame resize is a visible twitch of the whole box.

import "../../consts"
import "../../glass"
import "../../shared/state"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: panel

  readonly property int pad: ControlMetrics.px(16)

  // The gutter between cells. Tighter than the brutalist themes' — there is no
  // hard shadow here that needs somewhere to land.
  readonly property int gap: ControlMetrics.px(2)

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

  // Solid fill first, glass over it — the same two-layer build the control
  // center uses, at the same weights, so the two popups read as the same kind
  // of object hanging off the same bar.
  Rectangle {
    anchors.fill: parent
    radius: ControlMetrics.px(16)
    color: Theme.get_color("panel")
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
      spacing: panel.gap * 2

      CalendarArrow {
        icon: "chevronLeft"
        onClicked: CalendarState.step(-1)
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        CalendarBlock {
          anchors.fill: parent

          // Rim left as the resting gradient. Collapsing it would claim the
          // header is in some state, and the header is just a label.
          fresnel: home.containsMouse && !CalendarState.onToday ? 0.85 : 0.55
          Behavior on fresnel {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
          }
        }

        Text {
          anchors.centerIn: parent

          text: CalendarState.monthLabel.toUpperCase() + " " + CalendarState.viewYear
          font.family: "Oswald"
          font.pixelSize: ControlMetrics.px(15)
          font.weight: 600
          font.letterSpacing: 1
          color: Theme.get_color("fg")
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

          font.family: "Oswald"
          font.pixelSize: ControlMetrics.px(11)
          font.weight: 500
          font.letterSpacing: 1
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
