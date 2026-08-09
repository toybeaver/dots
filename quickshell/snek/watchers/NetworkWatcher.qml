// Wifi state, the local IPv4 address, and airplane mode.
//
// Quickshell's Networking singleton fills in ASYNCHRONOUSLY — for the first
// moment after the shell starts, wifiEnabled is false and devices is empty even
// on a connected machine. Everything here is therefore a binding. Reading any
// of it once, in a handler, gets you the pre-dbus defaults.

pragma Singleton

import "../state"

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick

Singleton {
  id: root

  // Bumped on a timer to force the scans below to re-run. QML only tracks the
  // properties a binding actually read, and both scans return early on the
  // first match — so a network that connects *after* the one being inspected
  // would never notify. The timer closes that hole.
  property int revision: 0

  readonly property var wifiDevice: {
    root.revision;
    ControlCenterState.open;

    const model = Networking.devices;
    if (!model) return null;
    for (const dev of model.values) {
      if (dev.type === DeviceType.Wifi) return dev;
    }
    return null;
  }

  readonly property var activeNetwork: {
    root.revision;
    ControlCenterState.open;

    const dev = root.wifiDevice;
    if (!dev || !dev.networks) return null;
    for (const net of dev.networks.values) {
      if (net.connected) return net;
    }
    return null;
  }

  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool wifiPresent: root.wifiDevice !== null
  readonly property string ssid: root.activeNetwork ? root.activeNetwork.name : ""

  // 0.0 to 1.0. Named `strength` because `signal` is a QML keyword.
  readonly property real strength: root.activeNetwork ? root.activeNetwork.signalStrength : 0

  property string ipv4: ""

  readonly property var btAdapter: Bluetooth.defaultAdapter
  readonly property bool btPresent: root.btAdapter !== null

  // Airplane mode is derived from the radios rather than stored, so it survives
  // a shell restart and stays honest if something else turns a radio off.
  //
  // With bluez down btAdapter is null and this collapses to "wifi is off",
  // which means toggling the wifi tile also lights the airplane tile. That is a
  // true statement about a machine whose only radio is wifi. It starts
  // distinguishing the two the moment bluetooth.service comes up, because the
  // adapter is a live binding.
  readonly property bool airplane:
    !Networking.wifiEnabled && (!root.btAdapter || !root.btAdapter.enabled)

  // Remembered so disengaging airplane mode does not switch bluetooth ON for
  // someone who had it off to begin with.
  property bool btWasEnabled: false

  function setWifi(on: bool) {
    Networking.wifiEnabled = on;
  }

  function setAirplane(on: bool) {
    if (on) {
      root.btWasEnabled = root.btAdapter ? root.btAdapter.enabled : false;
      Networking.wifiEnabled = false;
      if (root.btAdapter) root.btAdapter.enabled = false;
    } else {
      Networking.wifiEnabled = true;
      if (root.btAdapter && root.btWasEnabled) root.btAdapter.enabled = true;
    }
  }

  // NetworkDevice.address is the MAC (verified: BC:F1:05:92:ED:4D), and the
  // module exposes no IPv4 at all, so the address has to come from outside.
  Process {
    id: ipQuery

    command: ["sh", "-c",
      "ip -4 -o addr show dev '" + (root.wifiDevice ? root.wifiDevice.name : "") +
      "' 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1"]

    stdout: StdioCollector {
      onStreamFinished: root.ipv4 = this.text.trim()
    }
  }

  function refreshIp() {
    if (!root.wifiDevice || !root.wifiEnabled) {
      root.ipv4 = "";
      return;
    }
    ipQuery.running = true;
  }

  onActiveNetworkChanged: root.refreshIp()
  onWifiEnabledChanged: root.refreshIp()

  // Only scan while the panel is up. Nothing outside it reads any of this, and
  // polling dbus every few seconds to feed a hidden surface is waste.
  Timer {
    interval: 4000
    repeat: true
    running: ControlCenterState.open
    onTriggered: root.revision++
  }

  Connections {
    target: ControlCenterState
    function onOpenChanged() {
      if (ControlCenterState.open) root.refreshIp();
    }
  }
}
