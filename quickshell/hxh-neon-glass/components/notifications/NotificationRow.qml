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
import "../../glass"
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

  readonly property bool critical: row.item.urgency === "critical"

  GlassSurface {
    anchors.fill: parent

    radius: ControlMetrics.px(8)

    // Rim collapsed to the alert colour for a critical notification, resting
    // gradient otherwise. Urgency is the only thing that recolours a row —
    // everything else it carries, the text already says.
    edge: row.critical ? Theme.get_color("danger") : Theme.get_color("edge")
    edge2: row.critical ? Theme.get_color("danger") : Theme.get_color("edge_alt")

    // Softer than a sidebar pill's: this is a wide box inside an already
    // frosted panel, and the pill's full bevel reads as a second sheet of glass
    // stacked on the first.
    bevel: 3
    fresnel: row.critical ? 0.75 : 0.50
    spec: 0.12
    grain: 0.016
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
        font.family: "Oswald"
        font.pixelSize: ControlMetrics.px(9)
        font.letterSpacing: 1
        color: Theme.get_color("muted")
        elide: Text.ElideRight
      }

      Text {
        // Empty for anything that was already in mako's history when the shell
        // started — there is no arrival time to know. Better a gap than a
        // confident wrong number.
        text: NotificationWatcher.ago(row.item.time)
        font.family: "Oswald"
        font.pixelSize: ControlMetrics.px(9)
        color: Theme.get_color("muted")
      }

      Text {
        text: "✕"
        font.family: "Noto Sans"
        font.pixelSize: ControlMetrics.px(11)
        color: Theme.get_color("fg")

        opacity: kill.containsMouse ? 1.0 : 0.4
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
      font.family: "Oswald"
      font.pixelSize: ControlMetrics.px(13)
      font.weight: 600
      color: row.critical ? Theme.get_color("danger") : Theme.get_color("fg")
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
      color: Theme.get_color("fg")
      opacity: 0.8
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

          radius: ControlMetrics.px(5)
          color: hit.containsMouse ? Theme.get_color("edge_alt") : "transparent"
          border.color: Theme.get_color("edge_alt")
          border.width: 1

          Text {
            id: label
            anchors.centerIn: parent

            text: row.item.actions[action.modelData]
            font.family: "Oswald"
            font.pixelSize: ControlMetrics.px(10)
            color: hit.containsMouse ? Theme.get_color("panel")
                                     : Theme.get_color("fg")
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
