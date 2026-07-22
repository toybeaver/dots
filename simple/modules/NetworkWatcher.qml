pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
  id: root

  property NetworkDevice device: get_current_device()
  property Network network: get_current_network()

  function get_current_device(): NetworkDevice {
    for (const dev of Networking.devices.values) {
      if (dev.connected) return dev;
    }
    return null;
  }

  function get_current_network(): Network {
    if (device === null || device.networks === null) 
      return null;

    const values = device.networks.values;
    for (const net of values) {
      if (net.connected) return net;
    }
    return null;
  }

  function update_status() {
    device = get_current_device()
    network = get_current_network()
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: update_status()
  }
}
