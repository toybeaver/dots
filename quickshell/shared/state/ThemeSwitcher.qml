// Bridge to bin/shell-theme, the script that owns the theme list and the
// selection.
//
// Switching themes replaces the whole Quickshell process — a theme is a config
// directory, not a palette — so none of this can be done in-process. The script
// detaches itself before killing the shell that asked for the switch; see the
// comment on SHELL_THEME_DETACHED there for why that matters.
//
// Shared rather than per-theme: every theme needs an identical way out of
// itself, and the list of themes must not fork between them.

pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // bin/ sits beside the theme directories rather than inside one, so this is
  // resolved relative to whichever theme is currently running.
  readonly property string script: Quickshell.shellPath("../bin/shell-theme")

  // True from the moment a switch is requested. The shell is about to be torn
  // down, so this only ever has to survive long enough to stop a second click
  // from racing the first.
  property bool switching: false

  Process { id: runner }

  function step(direction: string): void {
    if (root.switching)
      return;

    root.switching = true;
    runner.command = [root.script, direction];
    runner.running = true;
  }

  function next(): void {
    root.step("next");
  }

  function prev(): void {
    root.step("prev");
  }

  // Jump straight to a named theme. Only reachable over IPC — the control
  // center walks the list rather than naming anything.
  function to(name: string): void {
    if (root.switching)
      return;

    root.switching = true;
    runner.command = [root.script, "set", name];
    runner.running = true;
  }
}
