// The default sink's volume, as a vertical slider.
//
// interactive:false on the base tile because this one drives its own MouseArea
// — the base's click-anywhere handler would otherwise swallow drags.

import "../../consts"
import "../../watchers"

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
      color: SnekStyles.get_color("fg")
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
        radius: width / 2
        color: "#22ffffff"
      }

      Rectangle {
        id: fill

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(width, parent.height * AudioWatcher.volume)
        radius: width / 2

        // Same magenta-to-cyan pair as the rim, stood on end. Cyan at the
        // bottom so the bar warms as it climbs.
        gradient: Gradient {
          GradientStop { position: 0.0; color: SnekStyles.get_color("glass_edge") }
          GradientStop { position: 1.0; color: SnekStyles.get_color("glass_edge_alt") }
        }

        opacity: AudioWatcher.muted ? 0.28 : 1.0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        // A bright cap makes the level readable against the gradient, which is
        // dark at both ends by design.
        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: ControlMetrics.px(3)
          radius: height / 2
          color: SnekStyles.get_color("fg")
          opacity: AudioWatcher.muted ? 0.0 : 0.9
        }
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
      font.family: "Oswald"
      font.pixelSize: ControlMetrics.px(13)
      font.weight: 600
      color: SnekStyles.get_color("fg")
      opacity: AudioWatcher.muted ? 0.45 : 0.9
    }
  }
}
