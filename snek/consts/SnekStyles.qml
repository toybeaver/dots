pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  readonly property var colors: ({
    "bg": "#3eb261",
    "fg": "#dcddaa",
    "warning": "#d9e01d",
    "danger": "#db4408"
  })

  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
