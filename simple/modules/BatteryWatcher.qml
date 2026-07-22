pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
  id: root
  property int percentage: {
    UPower.displayDevice.percentage*100
  }
  property string state: {
    get_charging_state()
  }

  signal update(int percentage, string state)

  function get_charging_state(): string {
    const state = UPower.displayDevice.state;
    if (state == UPowerDeviceState.FullyCharged) {
      return "FU";
    }
    if (state == UPowerDeviceState.Charging) {
      return "CH";
    }
    return "DC"
  }

  function update_status(): void {
    percentage = UPower.displayDevice.percentage*100
    state = get_charging_state()

    update(percentage, state)
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: update_status()
  }
}
