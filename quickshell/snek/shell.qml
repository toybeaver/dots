import "components"
import "components/control"

import Quickshell

Scope {
  Sidebar {}

  // Once for the whole shell, not per screen — it resolves the target screen
  // itself from whichever monitor has focus.
  ControlCenterIpc {}
}
