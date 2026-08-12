// Whether the calendar is open, which screen shows it, and which month it is
// showing.
//
// Non-visual, so it belongs in shared/ alongside the watchers: all three themes
// drive exactly this state and differ only in how they draw it. The month grid
// is computed here too — the arithmetic of "which 42 days does August 2026
// occupy" is not a design decision, and duplicating it per theme would mean
// three copies of an off-by-one waiting to happen.
//
// The month cursor lives HERE rather than inside the popup because the popup is
// never destroyed — it fades out and stays mapped — so a cursor stored in it
// would survive a close, and reopening the calendar next week would land on
// whatever month you last paged to. `toggle` resets it on the way in.

pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  property bool open: false

  // The ShellScreen whose popup is drawn. Null while closed.
  property var screen: null

  // Distance from the BOTTOM of the sidebar to the bottom of the date pill,
  // reported by SidebarDate as the bar lays itself out. The popup lines its own
  // bottom up with this, so it reads as hanging off the pill that opened it
  // rather than off the corner of the screen.
  //
  // Measured rather than written down as a constant: the pill's position is the
  // sum of four pill heights, four bottom margins and the ColumnLayout's own
  // spacing, so a number here would drift silently the first time a pill is
  // added or resized — and it would drift by a few pixels, which is exactly the
  // kind of wrong that never gets noticed and never stops looking off.
  //
  // This assumes the bar's window and the popup's window share a bottom edge.
  // They do: the bar is the only surface in the shell that reserves space.
  property real anchorInset: 0

  // ---- the clock ----------------------------------------------------------

  // Minutes, not Seconds. Nothing on a calendar changes more than once a day;
  // the only reason to tick at all is so a popup left open across midnight
  // moves its "today" marker without being reopened.
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // Today as a sortable string, and the two numbers pulled back out of it.
  //
  // Going through a formatted string rather than reading `clock.date` directly
  // is what keeps the grid from rebuilding every minute: this value changes
  // once a day, so everything bound to it sits still for the other 1439.
  readonly property string todayKey: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
  readonly property int todayYear: parseInt(root.todayKey.substring(0, 4), 10)
  readonly property int todayMonth: parseInt(root.todayKey.substring(5, 7), 10)

  // ---- the month on screen ------------------------------------------------

  // Bound to today at startup, which is also how they get their first value.
  // Stepping months ASSIGNS to them and so breaks the binding permanently —
  // deliberate, and the reason `toggle` calls showToday() rather than relying
  // on the binding to have survived.
  property int viewYear: root.todayYear

  // 1-based, unlike JS Date's month. Every conversion to a Date below
  // subtracts one; there is no second convention anywhere in this file.
  property int viewMonth: root.todayMonth

  readonly property bool onToday: root.viewYear === root.todayYear
    && root.viewMonth === root.todayMonth

  readonly property string monthLabel:
    Qt.locale().standaloneMonthName(root.viewMonth - 1, Locale.LongFormat)

  // Column headings, rotated so the week starts where the locale says it does
  // rather than where the author's habits do.
  readonly property var weekdayLabels: {
    const locale = Qt.locale();
    const out = [];
    for (let i = 0; i < 7; i++) {
      out.push(locale.standaloneDayName((locale.firstDayOfWeek + i) % 7,
                                        Locale.ShortFormat));
    }
    return out;
  }

  // The grid: always 42 cells, six rows of seven. Never five rows and never
  // seven.
  //
  // A grid that changes height between months makes the popup jump as you page
  // through it, and since the popup is bottom-anchored to the date pill it
  // would jump upward — the whole box moving because February is short. Six
  // rows covers the worst case (a 31 day month whose 1st falls on the last day
  // of its first week: 6 + 31 = 37) with a row to spare.
  //
  // Each cell is { day, inMonth, isToday }. `inMonth` rather than a null for
  // the leading and trailing days: they are drawn, just dimmed, which is what
  // makes the first and last weeks readable as weeks.
  readonly property var cells: {
    const out = [];
    const lead = (new Date(root.viewYear, root.viewMonth - 1, 1).getDay()
                  - Qt.locale().firstDayOfWeek + 7) % 7;

    for (let i = 0; i < 42; i++) {
      // Day-of-month arithmetic through the Date constructor rather than by
      // hand: `1 - lead` is negative for most months and rolls back into the
      // previous one — including across a year boundary — without this file
      // ever needing to know how long February is.
      const d = new Date(root.viewYear, root.viewMonth - 1, 1 - lead + i);
      out.push({
        "day": d.getDate(),
        "inMonth": d.getMonth() === root.viewMonth - 1
          && d.getFullYear() === root.viewYear,
        "isToday": Qt.formatDateTime(d, "yyyy-MM-dd") === root.todayKey
      });
    }
    return out;
  }

  function step(months: int) {
    let m = root.viewMonth + months;
    let y = root.viewYear;
    while (m < 1)  { m += 12; y -= 1; }
    while (m > 12) { m -= 12; y += 1; }
    root.viewMonth = m;
    root.viewYear = y;
  }

  function showToday() {
    root.viewYear = root.todayYear;
    root.viewMonth = root.todayMonth;
  }

  // ---- open and close -----------------------------------------------------

  // Resets the month on the way IN, not on the way out. Closing only fades the
  // popup, which stays on screen for another 160ms — resetting there would show
  // the month name snapping back behind the fade.
  function toggle(scr) {
    if (root.open && root.screen === scr) {
      root.open = false;
      return;
    }
    root.showToday();
    ControlCenterState.close();
    root.screen = scr;
    root.open = true;
  }

  function close() {
    root.open = false;
  }

  // The calendar and the control center are both full-screen click-catchers on
  // the overlay layer, so two open at once means one is stranded underneath the
  // other with no way to reach it. The catchers make that nearly unreachable by
  // mouse — but the control center also answers an IPC handler behind a
  // keybind, which goes through none of them.
  //
  // One-directional on purpose: the calendar knows about the control center and
  // not the other way round. Two singletons referencing each other would be a
  // question about initialisation order, and this way there is no question.
  Connections {
    target: ControlCenterState
    function onOpenChanged() {
      if (ControlCenterState.open) root.open = false;
    }
  }
}
