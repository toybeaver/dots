import "components"
import "components/control"
import "shared/state"

import Quickshell

Scope {
  Sidebar {}

  // Once for the whole shell, not per screen — it resolves the target screen
  // itself from whichever monitor has focus.
  ControlCenterIpc {}

  // Theme switching over IPC, so a keybind can reach it too.
  ThemeIpc {}

  // Closes the calendar, the control center and the notification list when the
  // workspace changes — they belong to the workspace you left.
  WorkspaceDismiss {}
}
