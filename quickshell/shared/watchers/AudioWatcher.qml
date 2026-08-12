// The default audio sink, as a flat set of properties.

pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: root.sink !== null && root.sink.ready && root.sink.audio !== null

  readonly property real volume: root.ready ? root.sink.audio.volume : 0
  readonly property bool muted: root.ready ? root.sink.audio.muted : false

  // Pipewire objects carry no data until something tracks them. Without this
  // the sink exists but `audio` stays null, so volume reads 0 and every write
  // is silently dropped.
  PwObjectTracker {
    objects: root.sink !== null ? [root.sink] : []
  }

  // Clamped to unity deliberately. Pipewire will happily amplify well past 100%
  // and a slider that can blow out the speakers is not a control worth having.
  function setVolume(v: real) {
    if (!root.ready) return;
    root.sink.audio.volume = Math.max(0, Math.min(1, v));
  }

  function toggleMute() {
    if (!root.ready) return;
    root.sink.audio.muted = !root.sink.audio.muted;
  }
}
