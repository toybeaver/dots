// The default sink's volume, as a vertical slider.
//
// interactive:false on the base tile because this one drives its own MouseArea
// — the base's click-anywhere handler would otherwise swallow drags.

import "../../consts"
import "../../shared/watchers"

import Quickshell
import QtQuick
import QtQuick.Layouts

ControlTile {
  id: tile

  interactive: false

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: ControlMetrics.px(14)
    anchors.bottomMargin: ControlMetrics.px(12)
    spacing: ControlMetrics.px(10)

    TileIcon {
      Layout.alignment: Qt.AlignHCenter
      name: "speaker"
      size: ControlMetrics.px(18)
      color: Theme.get_color("on_block")
      muted: AudioWatcher.muted
      opacity: AudioWatcher.muted ? 0.45 : 0.85
    }

    Item {
      id: track

      Layout.alignment: Qt.AlignHCenter
      Layout.fillHeight: true
      implicitWidth: ControlMetrics.px(10)

      Rectangle {
        anchors.fill: parent
        color: "#22ffffff"
      }

      Rectangle {
        id: fill

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(width, parent.height * AudioWatcher.volume)

        // Solid, where hxh-neon-glass runs a magenta-to-cyan gradient. That
        // gradient needed a bright cap on top to stay readable because it is
        // dark at both ends; a flat white bar is its own cap, so the cap is
        // gone rather than recoloured to something invisible against it.
        color: Theme.get_color("on_block")

        opacity: AudioWatcher.muted ? 0.28 : 1.0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
      }

      // Widened well past the 10px bar — a slider you have to hit precisely is
      // a slider you avoid using.
      MouseArea {
        id: grab

        anchors.fill: parent
        anchors.margins: -ControlMetrics.px(15)
        enabled: AudioWatcher.ready
        cursorShape: Qt.PointingHandCursor

        function applyAt(y: real) {
          AudioWatcher.setVolume(1 - ((y - ControlMetrics.px(15)) / track.height));
        }

        onPressed: mouse => grab.applyAt(mouse.y)
        onPositionChanged: mouse => { if (grab.pressed) grab.applyAt(mouse.y); }
        onWheel: wheel => AudioWatcher.setVolume(
          AudioWatcher.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: AudioWatcher.ready ? `${Math.round(AudioWatcher.volume * 100)}` : "--"
      font.family: "Adwaita Sans"
      font.pixelSize: ControlMetrics.px(13)
      font.weight: 800
      color: Theme.get_color("on_block")
      opacity: AudioWatcher.muted ? 0.45 : 0.9
    }
  }
}
