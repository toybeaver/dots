#!/usr/bin/env bash
# Install the greetd greeter into /etc/greetd.
#
# These are COPIED, not symlinked. The greeter runs as the `greeter` user and
# /home/toyb is 0700, so it cannot traverse into this repo — a symlink would
# resolve to something greeter cannot read and the greeter would fail to start.
# Re-run this after editing anything here.
#
#   sudo ./install.sh                 install the currently selected theme
#   sudo ./install.sh --theme NAME    install a specific theme's greeter
#
# The greeter is PER THEME, and it is baked in here rather than followed live:
# the greeter runs as the `greeter` user and cannot read /home, so it can never
# resolve the active-theme symlink the rest of the desktop uses. Whatever theme
# is selected when you run this is the one the login screen keeps.
#
# RE-RUN THIS AFTER SWITCHING THEMES if you want the login screen to follow.
#
# Every replaced file is backed up to /etc/greetd/backup-<timestamp>/.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "error: must run as root (sudo ./install.sh)" >&2
    exit 1
fi

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dst=/etc/greetd
repo="$(cd "$src/../.." && pwd)"

# Which theme's greeter to install.
#
# Read from the invoking user's state, not root's — this runs under sudo, so
# $HOME is /root and the selection would never be found. SUDO_USER is the
# reliable handle on whose desktop this actually is.
theme=""
if [ "${1:-}" = "--theme" ]; then
    theme="${2:-}"
    [ -n "$theme" ] || { echo "error: --theme needs a name" >&2; exit 1; }
else
    user_home=$(getent passwd "${SUDO_USER:-$(id -un)}" | cut -d: -f6)
    state="$user_home/.local/state/dots/theme"
    [ -r "$state" ] && theme=$(cat "$state" 2>/dev/null || true)
fi

# Fall back rather than fail. A greeter that will not install is a machine you
# cannot log into graphically.
if [ -z "$theme" ] || [ ! -f "$repo/quickshell/$theme/greeter/shell.qml" ]; then
    echo "warning: no greeter for theme \"${theme:-<unset>}\", falling back to hxh-neon-glass" >&2
    theme=hxh-neon-glass
fi
echo "installing greeter for theme: $theme"
backup="$dst/backup-$(date +%Y%m%d-%H%M%S)"

# environments is deliberately NOT installed. It is the live list of sessions,
# maintained by hand; the copy in the repo is a record, not a source of truth.
# Overwriting it from here would silently revert additions. The greeter reads
# /etc/greetd/environments at runtime, so that file stays authoritative.
#
# gtkgreet.css is installed even though the Quickshell greeter is the default,
# so the fallback documented in sway-config is always one edit away.
files=(sway-config gtkgreet.css)

mkdir -p "$backup"
for f in "${files[@]}"; do
    [ -e "$dst/$f" ] && cp -a "$dst/$f" "$backup/"
done
[ -d "$dst/quickshell" ] && cp -a "$dst/quickshell" "$backup/"

for f in "${files[@]}"; do
    install -m 0644 -o root -g root "$src/$f" "$dst/$f"
    echo "installed $dst/$f"
done

install -d -m 0755 -o root -g root "$dst/quickshell"
install -m 0644 -o root -g root \
    "$repo/quickshell/$theme/greeter/shell.qml" "$dst/quickshell/shell.qml"
echo "installed $dst/quickshell/shell.qml (theme: $theme)"

# Optional wallpaper. The greeter cannot read /home, so an image has to live
# somewhere world readable; shell.qml picks it up automatically if present.
if [ -n "${GREETER_BG:-}" ] && [ -f "$GREETER_BG" ]; then
    install -m 0644 -o root -g root "$GREETER_BG" "$dst/background.png"
    echo "installed $dst/background.png (from $GREETER_BG)"
fi

echo
echo "backup of previous files: $backup"
cat <<'NOTE'

VALIDATE BEFORE LOGGING OUT
    sway --validate --config /etc/greetd/sway-config

    Do NOT run `quickshell -p /etc/greetd/quickshell/shell.qml` directly in your
    session. That surface takes exclusive keyboard focus on the overlay layer
    and will grab your keyboard. Preview it nested instead:

        printf 'exec "quickshell -p /etc/greetd/quickshell/shell.qml; swaymsg exit"\nbindsym Mod4+q exec swaymsg exit\n' > /tmp/greet-preview
        WLR_BACKENDS=wayland sway --config /tmp/greet-preview

TESTING
    Do NOT run `systemctl restart greetd` while logged in — your session is a
    child of greetd and would be killed. Log out or reboot to see the greeter.

IF THE GREETER FAILS TO START
    Switch to a TTY with Ctrl+Alt+F2 and log in, then either:
      roll back:  sudo cp -a BACKUP_DIR/. /etc/greetd/
      or fall back to gtkgreet by editing the exec line in
                  /etc/greetd/sway-config (the alternative is commented there)
    then: sudo systemctl restart greetd
NOTE
echo "    BACKUP_DIR = $backup"
