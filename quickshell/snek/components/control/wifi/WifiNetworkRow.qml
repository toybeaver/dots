// One network in the list.
//
// Collapsed it is icon + SSID + security. A secured network that is not already
// saved splits in half on click, giving the right half to a password field and
// a connect button, then collapses again once it succeeds.

import "../../../consts"
import "../../../glass"
import "../../../watchers"
import ".."

import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

Item {
  id: row

  required property var network

  property bool expanded: false
  property bool failed: false

  readonly property bool valid: row.network !== null && row.network !== undefined

  // EAP cannot be driven by connectWithPsk, so these are listed for
  // completeness but not connectable. Dimmed rather than clickable-and-broken.
  readonly property bool enterprise: row.valid && NetworkWatcher.isEnterprise(row.network.security)

  readonly property bool connecting: row.valid && row.network.state === ConnectionState.Connecting
  readonly property bool secured: row.valid && NetworkWatcher.needsPassword(row.network.security)
  readonly property bool known: row.valid && row.network.known

  readonly property bool actionable: row.valid && !row.enterprise && !row.connecting

  implicitHeight: ControlMetrics.px(34)

  function activate() {
    if (!row.actionable) return;

    // Saved networks and open ones need no prompt; everything else does.
    if (row.known || !row.secured) {
      NetworkWatcher.connectTo(row.network, "");
      return;
    }
    row.expanded = !row.expanded;
    if (row.expanded) password.forceActiveFocus();
  }

  function submit() {
    if (password.text.length === 0) return;
    NetworkWatcher.connectTo(row.network, password.text);
    row.expanded = false;
  }

  GlassSurface {
    anchors.fill: parent
    radius: ControlMetrics.px(9)

    // Same idiom as everywhere else in this shell: state collapses the rim to
    // one colour instead of introducing a second visual language.
    edge: row.failed ? SnekStyles.get_color("danger")
        : row.connecting ? SnekStyles.get_color("glass_edge_alt")
        : SnekStyles.get_color("glass_edge")
    edge2: row.failed ? SnekStyles.get_color("danger")
         : SnekStyles.get_color("glass_edge_alt")

    fresnel: hover.containsMouse && row.actionable ? 0.90 : 0.60
    Behavior on fresnel { NumberAnimation { duration: 120 } }
  }

  // Matches the power tiles' arm window, so "something went red" always means
  // the same thing and lasts the same time across the shell.
  Timer {
    id: failTimer
    interval: 3000
    onTriggered: row.failed = false
  }

  Connections {
    target: row.valid ? row.network : null

    function onConnectionFailed(reason) {
      row.failed = true;
      failTimer.restart();

      // A rejected password is the one failure with an obvious next step, so
      // reopen the field rather than making the user click the row again.
      if (reason === ConnectionFailReason.NoSecrets) {
        password.text = "";
        row.expanded = true;
        password.forceActiveFocus();
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    spacing: 0

    // ---- left half: the network itself ----
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      // Dimming the whole half is what marks an unsupported network, so the
      // icon, name and security all fade together.
      opacity: row.enterprise ? 0.38 : 1.0

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: ControlMetrics.px(12)
        anchors.rightMargin: ControlMetrics.px(11)
        spacing: ControlMetrics.px(10)

        TileIcon {
          Layout.alignment: Qt.AlignVCenter
          name: "wifi"
          size: ControlMetrics.px(19)
          color: SnekStyles.get_color("fg")
          bars: row.valid ? NetworkWatcher.bars(row.network.signalStrength) : 0
          opacity: hover.containsMouse && row.actionable ? 1.0 : 0.8
        }

        Text {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          text: row.valid ? row.network.name : ""
          font.family: "Oswald"
          font.pixelSize: ControlMetrics.px(13)
          font.weight: row.known ? 600 : 500
          color: SnekStyles.get_color("fg")
          elide: Text.ElideRight
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          text: row.failed ? "failed"
              : row.connecting ? "connecting…"
              : row.valid ? NetworkWatcher.securityLabel(row.network.security)
              : ""
          font.family: "Noto Sans"
          font.pixelSize: ControlMetrics.px(10)
          color: row.failed ? SnekStyles.get_color("danger") : SnekStyles.get_color("muted")
        }
      }

      MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.actionable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: row.activate()
      }
    }

    // ---- right half: password entry ----
    Item {
      Layout.preferredWidth: row.expanded ? Math.round(row.width * 0.5) : 0
      Layout.fillHeight: true
      clip: true

      Behavior on Layout.preferredWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
      }

      RowLayout {
        anchors.fill: parent
        anchors.rightMargin: ControlMetrics.px(10)
        anchors.topMargin: ControlMetrics.px(6)
        anchors.bottomMargin: ControlMetrics.px(6)
        spacing: ControlMetrics.px(8)

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: ControlMetrics.px(6)
          color: "#26ffffff"

          TextInput {
            id: password

            anchors.fill: parent
            anchors.leftMargin: ControlMetrics.px(9)
            anchors.rightMargin: ControlMetrics.px(9)
            verticalAlignment: TextInput.AlignVCenter

            echoMode: TextInput.Password
            passwordCharacter: "•"
            font.family: "Noto Sans"
            font.pixelSize: ControlMetrics.px(12)
            color: SnekStyles.get_color("fg")
            selectByMouse: true
            clip: true

            onAccepted: row.submit()

            // Swallowed so it collapses the field instead of reaching the
            // overlay, where it would jump back a page mid-typing.
            Keys.onEscapePressed: event => {
              row.expanded = false;
              event.accepted = true;
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: password.text.length === 0
              text: "password"
              font: password.font
              color: SnekStyles.get_color("muted")
            }
          }
        }

        Item {
          Layout.preferredWidth: connectLabel.implicitWidth + ControlMetrics.px(16)
          Layout.fillHeight: true

          Rectangle {
            anchors.fill: parent
            radius: ControlMetrics.px(6)
            color: SnekStyles.get_color("fg")
            opacity: password.text.length === 0 ? 0.06
                   : (connectMouse.containsMouse ? 0.20 : 0.12)
            Behavior on opacity { NumberAnimation { duration: 120 } }
          }

          Text {
            id: connectLabel
            anchors.centerIn: parent
            text: "connect"
            font.family: "Oswald"
            font.pixelSize: ControlMetrics.px(11)
            font.weight: 500
            color: SnekStyles.get_color("fg")
            opacity: password.text.length === 0 ? 0.4 : 1.0
          }

          MouseArea {
            id: connectMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: password.text.length > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: row.submit()
          }
        }
      }
    }
  }
}
