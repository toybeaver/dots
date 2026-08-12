// Notifications, read out of mako.
//
// mako stays the notification DAEMON — it owns org.freedesktop.Notifications
// and draws the popups, themed per theme in desktop/mako.conf. This file is a
// READER, not a second daemon. Quickshell ships its own NotificationServer, and
// using it would mean taking that bus name away from mako: only one process can
// hold it, so the two cannot coexist and every popup would have to be redrawn
// in QML per theme.
//
// What mako gives us, all verified against a live daemon:
//
//   fr.emersion.Mako   ListNotifications, ListHistory, InvokeAction,
//                      DismissNotifications, SetMode
//   PropertiesChanged  fires on BOTH 'Notifications' and 'Modes', on arrival,
//                      on dismissal and on a mode change
//
// so this is push-driven, not polled. `gdbus monitor` sits on that signal and
// every refresh below is a reaction to it.
//
// What mako does NOT give us, and what this file does about it:
//
//   no timestamps    stamped here, on first sight. Entries already in history
//                    when the shell starts get no time at all rather than a
//                    wrong one — see `primed`.
//   no icons         ListNotifications exposes app_icon as a string and it is
//                    empty in practice. There is no image data to have.
//   no way to clear  history is mako's ring buffer and nothing can empty it.
//                    Dismissal is bookkeeping kept HERE instead — a watermark
//                    for "clear all" and a set of ids for individual rows —
//                    persisted so a theme switch, which replaces the whole
//                    shell process, does not resurrect a cleared inbox.

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  // Newest first. Each entry is
  //   { id, appName, summary, body, urgency, actions, live, time }
  // where `live` means still on screen (so mako can dismiss it) and `time` is 0
  // for anything that predates the shell.
  property var list: []

  readonly property int count: root.list.length

  // Arrived since the center was last opened.
  readonly property int unread: {
    let n = 0;
    for (const item of root.list) {
      if (item.id > root.seenId) n++;
    }
    return n;
  }

  property bool dnd: false

  // Whether the arrival sound is muted — mako's `silent` mode. Sound only:
  // notifications still appear and still land in the list. Separate from `dnd`,
  // which suppresses the popup as well.
  //
  // Read back from mako on every refresh, so it stays right even if something
  // else changes the mode.
  property bool silent: false

  // What the USER last asked for, which is what gets persisted. Kept apart from
  // `silent` because that one follows mako, and at startup the two disagree for
  // as long as it takes the mode to be applied — long enough for an unrelated
  // save() to write the wrong value back over the file.
  property bool silentWanted: false

  // Whether the startup apply has run. See the note on silencer's onExited.
  property bool silenceApplied: false

  // ---- watermarks ---------------------------------------------------------
  //
  // Both persist. Without that a theme switch — which replaces the whole shell
  // process — would bring back every notification the user had already read and
  // cleared, which reads as the feature being broken rather than as the shell
  // having restarted.
  property int seenId: 0
  property int clearedId: 0

  // Ids dismissed one at a time, which the watermark cannot express — it only
  // says "everything up to here". Pruned against the watermark on every save,
  // so it stays the size of what is actually on screen rather than growing for
  // the life of the machine.
  property var hiddenIds: []

  FileView {
    id: store

    // ~/.local/state/dots, the same directory bin/shell-theme keeps the
    // selected theme in — deliberately NOT Quickshell.statePath(), which is
    // scoped per shell config. Each theme is a different config, so that would
    // give every theme its own watermarks and clearing your notifications in
    // one would leave them waiting in the next.
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
      + "/dots/notifications.json"

    // Read at startup rather than on first access, so the watermarks are in
    // place before the first refresh decides what counts as unread.
    preload: true

    // Absent on a fresh machine, which is not an error worth printing on every
    // startup until something has actually been read.
    printErrors: false

    onLoaded: {
      let saved = ({});
      try {
        saved = JSON.parse(store.text() || "{}");
      } catch (e) {
        // A truncated or hand-edited file. Starting from zero shows a few
        // already-read notifications again, which is a far better failure than
        // refusing to load.
      }
      root.seenId = saved.seen || 0;
      root.clearedId = saved.cleared || 0;
      root.hiddenIds = saved.hidden || [];
      root.silentWanted = saved.silent === true;
      root.loadedState = true;

      // Push it back into mako. A mode is runtime state there, so a silenced
      // desktop would start making noise again at every login without this.
      root.applySilence();

      root.refresh();
    }

    onLoadFailed: {
      // No file yet: the defaults above ARE the state, so writing is safe.
      root.loadedState = true;
      root.applySilence();
      root.refresh();
    }
  }

  // False until the file has been read. save() refuses to write before that, or
  // an action taken in the first moment after startup — a dismissal, a clear —
  // would persist in-memory defaults of zero over the real watermarks and
  // resurrect the entire history. The read is async and was measured taking
  // over a second, which is well inside the window where a theme switch has
  // already put the bar back on screen.
  property bool loadedState: false

  function save() {
    if (!root.loadedState) return;

    // Anything at or below the watermark is already excluded by it, so keeping
    // its id in the hidden set says the same thing twice.
    root.hiddenIds = root.hiddenIds.filter(id => id > root.clearedId);

    store.setText(JSON.stringify({
      "seen": root.seenId,
      "cleared": root.clearedId,
      "hidden": root.hiddenIds,
      "silent": root.silentWanted
    }));
  }

  // ---- reading mako -------------------------------------------------------

  // First sight of each id, in epoch ms. A plain object rather than a model:
  // it is a side table keyed by mako's id, and nothing binds to it.
  property var stamps: ({})

  // False until the first refresh has been folded in. Everything present at
  // that point already existed before the shell did, so it is stamped 0 —
  // "unknown" — rather than with the moment the shell happened to start, which
  // would render as a screenful of notifications that all arrived just now.
  property bool primed: false

  // ONE subprocess per refresh, not three. The three questions mako can answer
  // are asked together and come back as a single JSON document, so a refresh is
  // one spawn and one parse no matter how often the signal fires.
  Process {
    id: query

    command: ["sh", "-c",
      "{ printf '{\"live\":'; makoctl list -j;" +
      "  printf ',\"past\":'; makoctl history -j;" +
      "  modes=$(makoctl mode);" +
      "  printf ',\"dnd\":';" +
      "  if printf '%s\\n' \"$modes\" | grep -qx do-not-disturb; then printf true; else printf false; fi;" +
      "  printf ',\"silent\":';" +
      "  if printf '%s\\n' \"$modes\" | grep -qx silent; then printf true; else printf false; fi;" +
      "  printf '}'; }"]

    stdout: StdioCollector {
      onStreamFinished: root.ingest(this.text)
    }
  }

  function refresh() {
    // Restarting a Process that is still running is ignored, so a burst of
    // signals (an app posting three notifications at once) coalesces instead of
    // queueing three identical reads.
    if (!query.running) query.running = true;
  }

  function ingest(text: string) {
    let payload;
    try {
      payload = JSON.parse(text);
    } catch (e) {
      // mako gone, or answering something that is not JSON. Leave the last
      // known list in place rather than blanking the panel.
      return;
    }

    root.dnd = payload.dnd === true;
    root.silent = payload.silent === true;

    // Live entries win over history: the same notification appears in both for
    // a moment, and the live copy is the one that can still be dismissed.
    const byId = ({});
    for (const item of (payload.past || [])) byId[item.id] = { "row": item, "live": false };
    for (const item of (payload.live || [])) byId[item.id] = { "row": item, "live": true };

    const out = [];
    for (const key in byId) {
      const entry = byId[key];
      const item = entry.row;

      // Gone, as far as this shell is concerned. mako has no API to drop
      // anything from its history, so both of these are our own bookkeeping.
      if (item.id <= root.clearedId) continue;
      if (root.hiddenIds.indexOf(item.id) !== -1) continue;

      if (!(item.id in root.stamps)) {
        root.stamps[item.id] = root.primed ? Date.now() : 0;
      }

      out.push({
        "id": item.id,
        // Every string field can come back null — an app that set none, or
        // notify-send without -a. Collapsed to "" so the QML never has to.
        "appName": item.app_name || "",
        "summary": item.summary || "",
        "body": item.body || "",
        "urgency": item.urgency || "normal",
        "actions": item.actions || ({}),
        "live": entry.live,
        "time": root.stamps[item.id]
      });
    }

    out.sort((a, b) => b.id - a.id);
    root.list = out;
    root.primed = true;
  }

  // mako's own signal, watched rather than polled. One long-lived process for
  // the life of the shell.
  //
  // The line carries which property changed, so a mode toggle and an arriving
  // notification are told apart — but both want the same single refresh, so the
  // only thing this actually filters out is traffic from other interfaces.
  Process {
    id: monitor

    running: true
    command: ["gdbus", "monitor", "--session",
              "--dest", "org.freedesktop.Notifications",
              "--object-path", "/fr/emersion/Mako"]

    stdout: SplitParser {
      onRead: line => {
        if (line.indexOf("PropertiesChanged") !== -1) root.refresh();
      }
    }

    // mako is restarted rather than reloaded when it was started by something
    // other than shell-theme, and gdbus can lose the name it was following.
    // Come back rather than going quiet for the rest of the session.
    onExited: monitorRetry.start()
  }

  Timer {
    id: monitorRetry
    interval: 2000
    onTriggered: monitor.running = true
  }

  // A reconciliation, NOT a poll. Everything above is signal-driven; this only
  // exists so that a monitor which stopped delivering without exiting shows up
  // as two minutes of a stale badge rather than as a badge that is wrong until
  // the next reboot. Cheap: one subprocess, and only when nothing else fired.
  Timer {
    interval: 120000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // ---- relative time ------------------------------------------------------

  // Bumped so that "now" becomes "2m" without the panel being reopened. Rows
  // read it inside their own text binding; it is the only thing that makes a
  // formatted duration re-evaluate, since nothing else about the row changes.
  property int tick: 0

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.tick++
  }

  // "" when the arrival time is unknown — see `primed`. An empty string is the
  // honest answer for a notification that was already in mako's history when
  // the shell started; inventing "now" for it would be worse than saying
  // nothing.
  function ago(at: real): string {
    root.tick;
    if (!at) return "";

    const secs = Math.max(0, (Date.now() - at) / 1000);
    if (secs < 45)    return "now";
    if (secs < 3600)  return Math.round(secs / 60) + "m";
    if (secs < 86400) return Math.round(secs / 3600) + "h";
    return Math.round(secs / 86400) + "d";
  }

  // ---- acting on it -------------------------------------------------------

  // Works on every row, live or not, which is the point of keeping the hidden
  // set at all. A live one is dismissed through mako AND hidden here: dismissing
  // it only moves it into history, and without the second half it would come
  // straight back on the next refresh.
  function dismiss(id: int) {
    root.hiddenIds = root.hiddenIds.concat([id]);
    root.save();

    root.list = root.list.filter(item => item.id !== id);

    dismisser.command = ["makoctl", "dismiss", "-n", String(id)];
    dismisser.running = true;
  }

  function invoke(id: int, action: string) {
    invoker.command = ["makoctl", "invoke", "-n", String(id), action];
    invoker.running = true;
  }

  // Dismisses whatever is still on screen and moves the watermark past
  // everything else. The dismiss is what stops a visible popup from coming
  // straight back on the next refresh.
  function clearAll() {
    if (root.list.length > 0) {
      root.clearedId = root.list[0].id;

      // max(), not assignment. The newest row may have been dismissed one at a
      // time just before this, which leaves list[0] BELOW seenId — and a seen
      // watermark that walks backwards can only ever resurrect an unread badge
      // for something already read.
      root.seenId = Math.max(root.seenId, root.clearedId);
      root.save();
    }
    dismisser.command = ["makoctl", "dismiss", "-a"];
    dismisser.running = true;
    root.list = [];
  }

  function markRead() {
    if (root.list.length > 0 && root.list[0].id > root.seenId) {
      root.seenId = root.list[0].id;
      root.save();
    }
  }

  // ---- holding popups while the center is open ----------------------------
  //
  // mako's `reviewing` mode: invisible, and with no timeout. See the block in
  // each theme's mako.conf for what it does and why it is a mode of its own
  // rather than a second use of do-not-disturb.
  //
  // The no-timeout half is not just tidiness. An action can only be invoked
  // while mako still holds the notification — on expiry it emits
  // NotificationClosed and the sending app tears its side down too — so
  // holding arrivals open for as long as the panel is showing them is the only
  // window in which their buttons work at all.

  function holdPopups() {
    holder.command = ["makoctl", "mode", "-a", "reviewing"];
    holder.running = true;
  }

  function releasePopups() {
    // Dismiss BEFORE lifting the mode, and in one shell so the order is
    // guaranteed. Everything held has no timeout, so removing the mode on its
    // own would burst the whole batch onto the screen — permanently, since
    // there is nothing left to expire them. Dismissed, they land in history,
    // which is where the panel that just showed them keeps them anyway.
    holder.command = ["sh", "-c", "makoctl dismiss -a; makoctl mode -r reviewing"];
    holder.running = true;
  }

  // A shell that died with the center open leaves the mode behind, and a
  // leftover `reviewing` silences the desktop with nothing on screen to explain
  // it. Cleared on the way up.
  Component.onCompleted: {
    holder.command = ["makoctl", "mode", "-r", "reviewing"];
    holder.running = true;
  }

  Process { id: holder }

  // The speaker button in the notification center. Sound only — the popup and
  // the list are untouched.
  function toggleSilence() {
    root.silentWanted = !root.silentWanted;

    // Saved on intent rather than on what mako reports back, so the file is
    // right the instant it is clicked and cannot be raced by the refresh.
    root.save();
    root.applySilence();
  }

  function applySilence() {
    silencer.command = ["makoctl", "mode",
                        root.silentWanted ? "-a" : "-r", "silent"];
    silencer.running = true;
  }

  Process {
    id: silencer

    // Marks the point after which mako's answer can be trusted over ours. Until
    // the startup apply has actually run, mako still reports the mode from
    // before the shell existed, and mirroring that back would undo the very
    // setting we just restored.
    onExited: root.silenceApplied = true
  }

  // Put the setting BACK when mako disagrees, rather than adopting mako's
  // answer. The shell owns this switch — it is a button in the panel — and the
  // realistic way the two diverge is mako being restarted, which drops every
  // mode it was holding. Mirroring that was tried first and is the wrong way
  // round: a restart silently forgot the user's setting, and the panel then
  // reported sound was on because, by then, it was.
  //
  // Capped, so a mode mako will not accept cannot spin up processes forever.
  property int silenceRetries: 0

  onSilentChanged: {
    if (!root.silenceApplied) return;

    if (root.silent === root.silentWanted) {
      root.silenceRetries = 0;
      return;
    }
    if (root.silenceRetries < 3) {
      root.silenceRetries++;
      root.applySilence();
    }
  }

  function toggleDnd() {
    // -t, so mako owns the state and this never disagrees with it. Reading the
    // mode and setting its opposite would race with anything else that touches
    // modes; the refresh that follows the signal reports what actually
    // happened.
    dnder.running = true;
  }

  Process { id: dismisser }
  Process { id: invoker }
  Process {
    id: dnder
    command: ["makoctl", "mode", "-t", "do-not-disturb"]
  }
}
