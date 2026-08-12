// One notification in the center.
//
// Height comes from the content, not from a constant: a one-line "Build
// finished" and a five-line stack trace are both notifications, and giving them
// the same box means padding one or truncating the other.
//
// Dismissal works on EVERY row, live or not. mako cannot remove anything from
// its own history, so a dismissed row is remembered shell-side — see the header
// of NotificationWatcher. Offering it only on live rows would have been the
// easier build and a worse one: two rows that look identical would behave
// differently for a reason nothing on screen explains.

import "../../consts"
import "../../brutal"
import "../../shared/watchers"

import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: row

  // { id, appName, summary, body, urgency, actions, live, time }
  required property var item

  readonly property int pad: ControlMetrics.px(10)

  implicitHeight: content.implicitHeight + row.pad * 2

  // Urgency is the only thing that recolours a row. Everything else in this
  // theme spends hue on meaning, and "this one is urgent" is the only meaning a
  // notification carries that the text does not already say.
  readonly property color accent: row.item.urgency === "critical"
    ? Theme.get_color("danger")
    : Theme.get_color("neutral")

  BrutalSurface {
    anchors.fill: parent

    // LIGHT twin: hue in the block, outline and shadow are both ink.
    base: row.accent
    edge: Theme.get_color("edge")

    borderWidth: ControlMetrics.px(2)
    offset: ControlMetrics.px(3)
  }

  ColumnLayout {
    id: content

    x: row.pad
    y: row.pad
    width: row.width - row.pad * 2

    spacing: ControlMetrics.px(3)

    // ---- app, age, dismiss ------------------------------------------------
    RowLayout {
      Layout.fillWidth: true
      spacing: ControlMetrics.px(6)

      Text {
        Layout.fillWidth: true

        text: row.item.appName.toUpperCase()
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(9)
        font.weight: 800
        color: Theme.get_color("on_block_dim")
        elide: Text.ElideRight
      }

      Text {
        // Empty for anything that was already in mako's history when the shell
        // started — there is no arrival time to know. Better a gap than a
        // confident wrong number.
        text: NotificationWatcher.ago(row.item.time)
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(9)
        font.weight: 700
        color: Theme.get_color("on_block_dim")
      }

      Text {
        text: "✕"
        font.family: "Adwaita Sans"
        font.pixelSize: ControlMetrics.px(11)
        font.weight: 800
        color: Theme.get_color("on_block")

        opacity: kill.containsMouse ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: 120 } }

        MouseArea {
          id: kill
          anchors.fill: parent
          anchors.margins: -ControlMetrics.px(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: NotificationWatcher.dismiss(row.item.id)
        }
      }
    }

    // ---- summary ----------------------------------------------------------
    Text {
      Layout.fillWidth: true

      text: row.item.summary
      font.family: "Adwaita Sans"
      font.pixelSize: ControlMetrics.px(12)
      font.weight: 800
      color: Theme.get_color("on_block")
      wrapMode: Text.Wrap
      maximumLineCount: 2
      elide: Text.ElideRight
    }

    // ---- body -------------------------------------------------------------
    Text {
      Layout.fillWidth: true
      visible: row.item.body !== ""

      text: row.item.body
      font.family: "Noto Sans"
      font.pixelSize: ControlMetrics.px(10)
      color: Theme.get_color("on_block")
      wrapMode: Text.Wrap

      // Three lines, then an ellipsis. A notification center is a list of
      // things that happened, not a reader — a message that needs more than
      // this wants the app it came from.
      maximumLineCount: 3
      elide: Text.ElideRight
    }

    // ---- actions ----------------------------------------------------------
    //
    // LIVE ROWS ONLY, and this is a hard limit of mako rather than a choice.
    // When a notification expires mako emits NotificationClosed, the sending
    // app tears its side down, and InvokeAction against that id becomes a
    // silent no-op — `makoctl invoke` still exits 0, which is exactly how an
    // earlier version of this file came to claim the opposite. Measured on the
    // bus: a live invoke emits ActionInvoked, a history invoke emits nothing.
    //
    // So a button is drawn only while it can still do something. The window is
    // wider than it looks: opening the center puts mako in `reviewing` mode,
    // which holds arrivals open with no timeout for as long as the panel is up.
    Flow {
      Layout.fillWidth: true
      Layout.topMargin: ControlMetrics.px(2)
      spacing: ControlMetrics.px(4)

      visible: row.item.live && repeater.count > 0

      Repeater {
        id: repeater

        model: Object.keys(row.item.actions)

        Rectangle {
          id: action

          required property string modelData

          width: label.implicitWidth + ControlMetrics.px(12)
          height: label.implicitHeight + ControlMetrics.px(6)

          color: hit.containsMouse ? Theme.get_color("on_block") : "transparent"
          border.color: Theme.get_color("on_block")
          border.width: ControlMetrics.px(2)
          radius: 0
          antialiasing: false

          Text {
            id: label
            anchors.centerIn: parent

            text: row.item.actions[action.modelData]
            font.family: "Adwaita Sans"
            font.pixelSize: ControlMetrics.px(9)
            font.weight: 800

            // Inverts on hover rather than lifting: filling the block and
            // flipping the ink is the flattest possible way to say "pressed",
            // and this theme has no other kind.
            color: hit.containsMouse ? row.accent : Theme.get_color("on_block")
          }

          MouseArea {
            id: hit
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationWatcher.invoke(row.item.id, action.modelData)
          }
        }
      }
    }
  }
}
