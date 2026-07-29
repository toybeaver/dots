#!/usr/bin/env bash
# Screenshot helper for Hyprland, bound to Print in hyprland.lua.
#
#   screenshot.sh region   interactively select an area (default)
#   screenshot.sh screen   whole focused monitor
#   screenshot.sh window   the active window
#
# Every capture is saved to ~/Pictures/screenshots AND copied to the clipboard,
# so it can be pasted straight into a chat window.
#
# Requires: grim slurp wl-clipboard jq libnotify

set -euo pipefail

mode="${1:-region}"

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
region)
    # slurp exits non-zero when cancelled with Esc — that's not an error,
    # so bail out quietly instead of firing a failure notification.
    geom=$(slurp) || exit 0
    grim -g "$geom" "$file"
    ;;
window)
    geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    grim -g "$geom" "$file"
    ;;
screen)
    grim -o "$(hyprctl activeworkspace -j | jq -r .monitor)" "$file"
    ;;
*)
    notify-send -u critical "Screenshot" "Unknown mode: $mode"
    exit 1
    ;;
esac

wl-copy <"$file"
notify-send "Screenshot" "Copied to clipboard\n$file" -i "$file"
