#!/usr/bin/env bash
# Low-battery alerts: a notification plus a sound, once per threshold per discharge.
#
#   battery-monitor.sh start        watch the battery (run once from autostart)
#   battery-monitor.sh test         play every alert in turn (20, 10, 7, 6, 5)
#   battery-monitor.sh test <pct>   play the alert that would fire at <pct>%
#
# Alerts:  20% normal | 10% critical | 7%, 6%, 5% critical
# Each threshold fires once while discharging. Plugging in re-arms all of them, and so
# does charging back above a threshold.
# Needs: libnotify (notify-send) and one of pw-play / paplay / ffplay / mpv for sound.
 
POLL="${BATTERY_POLL:-30}"                                   # seconds between checks
 
THRESHOLDS=(20 10 7 6 5)                                     # keep in descending order
declare -A LEVEL=( [20]=normal [10]=critical [7]=critical [6]=critical [5]=critical )
 
# Sounds. Swap these for your own files (ogg/wav/flac), e.g. in ~/.config/hypr/sounds/
SOUND_DIR="${BATTERY_SOUND_DIR:-/usr/share/sounds/freedesktop/stereo}"
SOUND_NORMAL="${BATTERY_SOUND_NORMAL:-$SOUND_DIR/dialog-warning.oga}"
SOUND_CRITICAL="${BATTERY_SOUND_CRITICAL:-$SOUND_DIR/suspend-error.oga}"
 
# ── Helpers ──────────────────────────────────────────────────────────────────
find_battery() {
    local b
    for b in "${BATTERY_SYSFS:-/sys/class/power_supply}"/BAT*; do
        [ -r "$b/capacity" ] && { echo "$b"; return 0; }
    done
    return 1
}
 
# Plays in the background so the loop (and the notification) never waits for it.
play_sound() {
    local f="$1"
    [ -f "$f" ] || return 0
    {
        if   command -v pw-play >/dev/null 2>&1; then pw-play "$f"
        elif command -v paplay  >/dev/null 2>&1; then paplay "$f"
        elif command -v ffplay  >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet "$f"
        elif command -v mpv     >/dev/null 2>&1; then mpv --no-video --really-quiet "$f"
        fi
    } >/dev/null 2>&1 &
}
 
alert() {   # alert <percent> <normal|critical>
    local pct="$1" level="$2" title body icon sound
    if [ "$level" = "critical" ]; then
        icon="battery-empty"; sound="$SOUND_CRITICAL"
        if [ "$pct" -le 7 ]; then
            title="Battery critical"; body="${pct}% left. Plug in now or the laptop will shut down."
        else
            title="Battery very low"; body="${pct}% left. Plug in now."
        fi
    else
        icon="battery-caution"; sound="$SOUND_NORMAL"
        title="Battery low"; body="${pct}% left. Plug in soon."
    fi
    # The synchronous hint makes each alert replace the previous one instead of stacking
    notify-send -a "Battery" -u "$level" -i "$icon" \
        -h string:x-canonical-private-synchronous:battery-alert "$title" "$body"
    play_sound "$sound"
}
 
declare -A fired
 
check() {   # one pass; needs $BAT
    local cap status t hit=""
    cap="$(<"$BAT/capacity")"
    status="$(<"$BAT/status")"
 
    # Anything but "Discharging" (Charging, Full, Not charging) re-arms every alert
    if [ "$status" != "Discharging" ]; then fired=(); return 0; fi
 
    for t in "${THRESHOLDS[@]}"; do
        if [ "$cap" -gt "$t" ]; then unset "fired[$t]"; continue; fi   # charged back above it
        [ -n "${fired[$t]:-}" ] && continue
        fired[$t]=1
        hit="$t"                        # descending order: the last hit is the most severe
    done
    [ -n "$hit" ] && alert "$cap" "${LEVEL[$hit]}"
    return 0
}
 
level_for() {   # level for a given percentage (used by "test <pct>")
    local pct="$1" t lvl="normal"
    for t in "${THRESHOLDS[@]}"; do
        [ "$pct" -le "$t" ] && lvl="${LEVEL[$t]}"
    done
    echo "$lvl"
}
 
main() {
    case "${1:-start}" in
        start)
            BAT="$(find_battery)" || exit 0          # no battery (desktop): nothing to do
            exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery-monitor.lock"
            flock -n 9 || exit 0                     # already running
            while :; do
                check
                sleep "$POLL"
            done
            ;;
        test)
            if [ -n "${2:-}" ]; then
                alert "$2" "$(level_for "$2")"
            else
                for t in "${THRESHOLDS[@]}"; do
                    alert "$t" "${LEVEL[$t]}"
                    sleep 4
                done
            fi
            ;;
        *)
            echo "Usage: ${0##*/} [start|test [percent]]" >&2
            exit 1
            ;;
    esac
}
 
# Run only when executed, so the functions can also be sourced for testing
if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
 
