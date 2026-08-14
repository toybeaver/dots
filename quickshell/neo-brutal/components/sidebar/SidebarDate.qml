// The date pill, and the button that opens the calendar.

import "../../shared/watchers"
import "../../shared/state"
import "../../consts"

import Quickshell
import QtQuick
import QtQuick.Layouts

SidebarPill {
  id: root

  // Which screen this bar belongs to, so the calendar opens on the display
  // whose pill was actually clicked.
  required property var targetScreen

  implicitHeight: 110
  Layout.bottomMargin: 10

  pressed: hit.pressed

  readonly property bool open: CalendarState.open
    && CalendarState.screen === root.targetScreen

  // Orange while open. Yellow pressed a shade further round the wheel, so the
  // pill still reads as itself rather than as a different pill.
  accent: root.open ? Theme.get_color("acc_orange")
                    : Theme.get_color("acc_yellow")

  // Where this pill's bottom edge sits, measured up from the bottom of the bar.
  // The calendar lines its own bottom up with it — see CalendarState.
  //
  // Reported from here rather than computed in the popup because this is the
  // only object that knows the answer: the layout decides it, and it changes if
  // any pill above or below is resized.
  readonly property real bottomInset: root.parent
    ? root.parent.height - (root.y + root.height)
    : 0

  onBottomInsetChanged: CalendarState.anchorInset = root.bottomInset
  Component.onCompleted: CalendarState.anchorInset = root.bottomInset

  ColumnLayout {
    anchors.fill: parent
    spacing: 1
    NumberDisplay {
      text: TimeWatcher.d
    }
    Separator {
      implicitWidth: 10
    }
    NumberDisplay {
      text: TimeWatcher.mo
    }
    Separator {
      implicitWidth: 10
    }
    NumberDisplay {
      text: TimeWatcher.y
    }
  }

  MouseArea {
    id: hit

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: CalendarState.toggle(root.targetScreen)
  }
}
