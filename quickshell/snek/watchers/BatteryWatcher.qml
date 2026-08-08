pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
  id: root
  property int percentage: {
    UPower.displayDevice.percentage * 100
  }
  property bool is_charging: {
    get_charging_state()
  }

  signal update(int percentage, bool is_charging)

  function get_charging_state(): bool {
    return UPower.displayDevice.state == UPowerDeviceState.Charging;
  }

  function update_status(): void {
    percentage = UPower.displayDevice.percentage*100
    is_charging = get_charging_state()

    update(percentage, is_charging)
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: update_status()
  }
}
