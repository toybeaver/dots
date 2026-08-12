// IPC face of ThemeSwitcher, so a theme can be changed without opening the
// control center:
//
//   quickshell/bin/shell-theme ipc call theme next    # also: prev, set <name>
//
// A Scope wrapping the handler rather than an IpcHandler directly: IpcHandler
// publishes EVERYTHING declared on it, so anything helper-shaped would show up
// as a callable method, and an untyped one fails outright with "Type QVariant
// cannot be used across IPC". Same reason ControlCenterIpc is shaped this way.
//
// This is also the only way to exercise a switch through the same code path the
// button uses — a Process inside the shell that is about to be replaced. That
// path cannot be reproduced from a terminal, where the parent never dies.

import Quickshell
import Quickshell.Io

Scope {
  IpcHandler {
    target: "theme"

    function next(): void {
      ThemeSwitcher.next();
    }

    function prev(): void {
      ThemeSwitcher.prev();
    }

    function set(name: string): void {
      ThemeSwitcher.to(name);
    }
  }
}
