#!/usr/bin/env bash
# Wallpaper manager for hyprpaper.
#
# The active wallpaper is a soft link ($LINK) that always points at the real image.
# hyprpaper.conf and the lockscreen both just use $LINK.
#
#   wallpaper.sh start        boot: reset to the FIRST wallpaper, start hyprpaper,
#                             then switch to the next one every $INTERVAL seconds
#   wallpaper.sh next | prev  step through the folder (resets the timer)
#   wallpaper.sh random       jump to a random one
#   wallpaper.sh first        jump back to the first one
#   wallpaper.sh set <file>   use a specific image
#   wallpaper.sh pick         choose one from a rofi grid with image previews

# ── Settings ─────────────────────────────────────────────────────────────────
WALL_DIR="${WALL_DIR:-$HOME/Pictures/Wallpapers/wallhaven}"     # scanned recursively
LINK="${WALLPAPER_LINK:-$HOME/Pictures/Wallpapers/current}"
INTERVAL="${WALLPAPER_INTERVAL:-600}"                            # seconds (10 min)
FIT="${WALLPAPER_FIT:-cover}"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-daemon.pid"
ROFI_THEME="${WALLPAPER_ROFI_THEME:-$HOME/.config/rofi/wallpaper.rasi}"
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
THUMB_SIZE="480x270"                                            # preview size (16:9)
IM="$(command -v magick || command -v convert)"                 # ImageMagick, for previews

# ── Helpers ──────────────────────────────────────────────────────────────────
notify() { command -v notify-send >/dev/null 2>&1 && notify-send -t 1500 "Wallpaper" "$1"; }

# Re-scan every time so new files in the folder are picked up automatically.
scan() {
    mapfile -t walls < <(find -L "$WALL_DIR" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort)
    n=${#walls[@]}
    if [ "$n" -eq 0 ]; then
        echo "No wallpapers found in $WALL_DIR" >&2
        notify "No wallpapers found in $WALL_DIR"
        exit 1
    fi
}

# Position of the current wallpaper in the array (-1 if the link is missing/broken).
current_index() {
    idx=-1
    local cur i
    cur="$(readlink -f "$LINK" 2>/dev/null)"
    [ -n "$cur" ] || return 0
    for i in "${!walls[@]}"; do
        if [ "$(readlink -f "${walls[$i]}")" = "$cur" ]; then idx=$i; break; fi
    done
}

# Point the link at $1 and show it. hyprpaper is sent the real path (not the link),
# so it always sees a new path and reloads. If hyprpaper isn't running yet, start it:
# it reads hyprpaper.conf, which points at the link we just updated.
apply() {
    local target
    target="$(readlink -f "$1")"
    [ -f "$target" ] || { echo "Not a file: $1" >&2; exit 1; }

    mkdir -p "$(dirname "$LINK")"
    ln -sfn "$target" "$LINK"

    if pgrep -x hyprpaper >/dev/null 2>&1; then
        hyprctl hyprpaper wallpaper ",$target,$FIT" >/dev/null
    else
        setsid -f hyprpaper >/dev/null 2>&1
    fi
    [ "$2" = "notify" ] && notify "$(basename "$target")"
}

step() {   # step <next|prev|random|first> [notify]
    scan
    current_index
    local t
    case "$1" in
        next)   t="${walls[$(( (idx + 1) % n ))]}" ;;                # idx=-1 -> first
        prev)   [ "$idx" -lt 0 ] && idx=0
                t="${walls[$(( (idx - 1 + n) % n ))]}" ;;
        first)  t="${walls[0]}" ;;
        random) t="${walls[$(( RANDOM % n ))]}"
                if [ "$n" -gt 1 ] && [ "$idx" -ge 0 ]; then
                    while [ "$(readlink -f "$t")" = "$(readlink -f "${walls[$idx]}")" ]; do
                        t="${walls[$(( RANDOM % n ))]}"
                    done
                fi ;;
    esac
    apply "$t" "$2"
}

# Previews for the rofi picker: small cached thumbnails, so rofi doesn't have to load
# 4K originals. A thumbnail is rebuilt when its image changes (path + mtime).
make_thumb() {   # make_thumb <image> <thumbnail>
    local tmp="$2.tmp.$$.jpg"
    nice -n 19 "$IM" "$1[0]" -thumbnail "${THUMB_SIZE}^" -gravity center -extent "$THUMB_SIZE" \
        -background '#0f1416' -flatten -quality 85 "$tmp" 2>/dev/null \
        && mv -f "$tmp" "$2" || rm -f "$tmp"
}

# Fills the thumbs array (same order as walls), creating missing previews 4 at a time.
build_thumbs() {
    thumbs=()
    if [ -z "$IM" ]; then thumbs=("${walls[@]}"); return; fi     # no ImageMagick: use the originals
    mkdir -p "$THUMB_DIR"
    find "$THUMB_DIR" -type f -mtime +30 -delete 2>/dev/null
    local f t key
    for f in "${walls[@]}"; do
        key="$(printf '%s|%s' "$f" "$(stat -c %Y "$f")" | md5sum | cut -d' ' -f1)"
        t="$THUMB_DIR/$key.jpg"
        thumbs+=("$t")
        [ -s "$t" ] && continue
        make_thumb "$f" "$t" &
        while [ "$(jobs -rp | wc -l)" -ge 4 ]; do wait -n; done
    done
    wait
}

# Restart the auto-switch timer after a manual change.
nudge() {
    local pid
    [ -f "$PIDFILE" ] && pid="$(cat "$PIDFILE" 2>/dev/null)"
    [ -n "$pid" ] && kill -USR1 "$pid" 2>/dev/null
    return 0
}

daemon() {
    # Only one daemon at a time
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
        exit 0
    fi
    echo $$ > "$PIDFILE"
    trap 'rm -f "$PIDFILE"' EXIT
    trap ':' USR1                       # manual change: just wake up and restart the timer

    step first ""                       # every boot starts at the first wallpaper
    ( build_thumbs ) >/dev/null 2>&1 &  # warm the picker previews in the background

    local sleeper
    while :; do
        sleep "$INTERVAL" & sleeper=$!
        if wait "$sleeper"; then        # slept the full interval -> advance
            step next ""
        fi                              # interrupted by USR1 -> the change already happened
        kill "$sleeper" 2>/dev/null
    done
}

# ── Commands ─────────────────────────────────────────────────────────────────
case "${1:-next}" in
    start)
        daemon
        ;;
    next|prev|random|first)
        step "$1" notify
        nudge
        ;;
    set)
        apply "${2:-}" notify
        nudge
        ;;
    pick)
        scan
        current_index
        build_thumbs
        choice="$(
            for i in "${!walls[@]}"; do
                printf '%s\0icon\x1f%s\n' "${walls[$i]#"$WALL_DIR"/}" "${thumbs[$i]}"
            done | rofi -dmenu -i -p "Wallpaper" -show-icons -no-sort -matching normal \
                -selected-row "$(( idx < 0 ? 0 : idx ))" -theme "$ROFI_THEME"
        )"
        [ -z "$choice" ] && exit 0
        apply "$WALL_DIR/$choice" notify
        nudge
        ;;
    *)
        echo "Usage: ${0##*/} [start|next|prev|random|first|set <file>|pick]" >&2
        exit 1
        ;;
esac
