#!/usr/bin/env bash
# Keep the laptop panel on and mirror every other monitor to it (Hyprland, Lua config).
# Nothing in here ever disables a monitor.
#
#   set-display.sh <monitor name> ensure   make sure the monitor is enabled
#   set-display.sh <monitor name> mirror   ensure, then mirror every other active
#                                          monitor to it (keeps each one's current mode)
#
# Needs: hyprctl, jq

display="$1"
state="$2"

if [ -z "$display" ] || [ -z "$state" ]; then
    echo "Usage: ${0##*/} <monitor> <ensure|mirror>" >&2
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

# Is the monitor in the list of active monitors?
is_active() {
    hyprctl -j monitors | jq -e --arg d "$display" 'any(.[]; .name == $d)' >/dev/null
}

case "$state" in
    ensure)
        is_active || enable_display
        ;;

    mirror)
        # let Hyprland settle after the plug-in event
        sleep 0.5
        is_active || enable_display

        # Every other active monitor that isn't already mirroring $display.
        # Prints "<name> <WxH@Hz>" using the mode it is running right now.
        hyprctl -j monitors | jq -r --arg d "$display" '
            .[]
            | select(.name != $d and .mirrorOf != $d)
            | "\(.name) \(.width)x\(.height)@\((.refreshRate * 100 | round) / 100)"
        ' | while read -r name mode; do
            hyprctl eval "hl.monitor({
                output   = '$name',
                mode     = '$mode',
                position = 'auto',
                scale    = 1,
                mirror   = '$display'
            })"
        done
        ;;

    *)
        echo "Usage: ${0##*/} <monitor> <ensure|mirror>" >&2
        exit 1
        ;;
esac

exit 0
