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

  // ---- scan results -------------------------------------------------------
  //
  // A frozen snapshot, deliberately. The live model reorders as signal
  // strengths drift, and a list that re-sorts under the cursor is hostile to
  // click on — you aim at one network and connect to another. Order is
  // recomputed only on entering the wifi view and on an explicit refresh.
  //
  // Objects can be destroyed by the backend while still referenced here, so
  // anything rendering this must tolerate nulls.
  property var networks: []

  readonly property bool wifiViewOpen: ControlCenterState.open && ControlCenterState.page === 1

  function refresh() {
    const dev = root.wifiDevice;
    if (!dev || !dev.networks) {
      root.networks = [];
      return;
    }

    const found = dev.networks.values.filter(n => n && n.name && n.name !== "");
    found.sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1;
      if (a.known !== b.known) return a.known ? -1 : 1;
      return b.signalStrength - a.signalStrength;
    });
    root.networks = found;
  }

  // Scanning costs power, so it only runs while the list is actually on screen.
  onWifiViewOpenChanged: {
    const dev = root.wifiDevice;
    if (dev && dev.scannerEnabled !== undefined) dev.scannerEnabled = root.wifiViewOpen;
    if (root.wifiViewOpen) root.refresh();
  }

  // ---- classification -----------------------------------------------------

  // Four discrete levels, matching the three arcs plus the bare dot.
  function bars(strength: real): int {
    if (strength >= 0.75) return 3;
    if (strength >= 0.50) return 2;
    if (strength >= 0.25) return 1;
    return 0;
  }

  function securityLabel(sec): string {
    switch (sec) {
      case WifiSecurityType.Open:          return "Open";
      case WifiSecurityType.Owe:           return "Open";
      case WifiSecurityType.StaticWep:
      case WifiSecurityType.DynamicWep:    return "WEP";
      case WifiSecurityType.WpaPsk:        return "WPA";
      case WifiSecurityType.Wpa2Psk:       return "WPA2";
      case WifiSecurityType.Sae:           return "WPA3";
      case WifiSecurityType.Wpa3SuiteB192: return "WPA3-E";
      case WifiSecurityType.WpaEap:
      case WifiSecurityType.Wpa2Eap:       return "Enterprise";
      case WifiSecurityType.Leap:          return "LEAP";
      default:                             return "";
    }
  }

  // EAP needs certificates and identities that connectWithPsk cannot supply,
  // and hand-building NMSettings for it is a feature of its own. These are
  // listed but not connectable — shown dimmed rather than failing mysteriously.
  function isEnterprise(sec): bool {
    return sec === WifiSecurityType.WpaEap
        || sec === WifiSecurityType.Wpa2Eap
        || sec === WifiSecurityType.Leap
        || sec === WifiSecurityType.Wpa3SuiteB192;
  }

  function needsPassword(sec): bool {
    return sec !== WifiSecurityType.Open && sec !== WifiSecurityType.Owe;
  }

  // ---- actions ------------------------------------------------------------

  // A saved network reconnects with its stored settings; anything else needs
  // the psk. Passing an empty psk to a secured network would fail with
  // NoSecrets rather than prompting, so callers must decide first.
  function connectTo(network, psk: string) {
    if (!network) return;
    if (psk && psk.length > 0) network.connectWithPsk(psk);
    else network.connect();
  }

  function disconnectActive() {
    if (root.activeNetwork) root.activeNetwork.disconnect();
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
