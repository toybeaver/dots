pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
  id: root

  readonly property PwNode sink: Pipewire.defaultAudioSink

  property int volume: sink.audio.volume*100
  property bool muted: sink.audio.muted

  function update_status(): void {
    volume = sink.audio.volume*100
    muted = sink.audio.muted
  }

  PwObjectTracker {
      objects: [root.sink]
  }
}
