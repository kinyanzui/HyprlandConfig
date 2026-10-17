#!/usr/bin/env bash
# Enable/disable a monitor in Hyprland (Lua config).
#
#   set-display.sh <monitor name> on       enable the monitor
#   set-display.sh <monitor name> off      disable it, but only if another monitor is active;
#                                          if it is the only one, lock the screen instead
#   set-display.sh <monitor name> rescue   re-enable it only if NO monitor is active
#                                          (used by the monitor.removed hook)
#
# Needs: hyprctl, jq

display="$1"
state="$2"

if [ -z "$display" ] || [ -z "$state" ]; then
    echo "Usage: ${0##*/} <monitor> <on|off|rescue>" >&2
    exit 1
fi

enable_display() {
    hyprctl eval "hl.monitor({
        output   = '$display',
        mode     = 'preferred',
        position = '0x0',
        scale    = 1,
        disabled = false
    })"
}

case "$state" in
    on)
        enable_display
        ;;

    off)
        # count active monitors other than the one we're about to disable
        others=$(hyprctl -j monitors | jq --arg d "$display" '[.[] | select(.name != $d)] | length')
        if (( others >= 1 )); then
            hyprctl eval "hl.monitor({ output = '$display', disabled = true })"
        else
            # nothing else connected: lock instead of blanking everything
            pidof hyprlock >/dev/null || hyprlock
        fi
        ;;

    rescue)
        # let Hyprland settle after the monitor event, then check
        sleep 0.5
        active=$(hyprctl -j monitors | jq 'length')
        if (( active == 0 )); then
            enable_display
        fi
        ;;

    *)
        echo "Usage: ${0##*/} <monitor> <on|off|rescue>" >&2
        exit 1
        ;;
esac

exit 0
