pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  readonly property var colors: ({
    "bg": "#3eb261",
    "fg": "#dcddaa",
    "warning": "#d9e01d",
    "danger": "#db4408",

    // Glass tokens, in #AARRGGBB. Consumed by shaders/glass.frag — the alpha
    // channel is a strength, not an opacity: the shader multiplies each by a
    // mask it derives from the pill's signed distance field.
    "glass_tint": "#0fffffff",
    "glass_edge": "#ffffffff"
  })


  function get_color(k: string): string {
    if (colors.hasOwnProperty(k)) {
      return colors[k];
    }
    return "red";
  }
}
