#!/usr/bin/env bash
#
# wallhaven-dl.sh — download wallpapers from wallhaven.cc via their API
#
# Requires: curl, jq
#
# Usage:
#   ./wallhaven-dl.sh
#
# Configure the CONFIG section below, or override any of it with
# environment variables / flags at call time, e.g.:
#   QUERY="mountains" LIMIT=10 ./wallhaven-dl.sh
#   ./wallhaven-dl.sh -q "cyberpunk" -L 10 -s toplist
#
# POOL / HISTORY / WHITELIST MODEL
# ---------------------------------
# OUTDIR holds a rotating pool of at most LIMIT wallpapers.
# On each run:
#   1. Any whitelisted ID missing its file is restored (re-downloaded).
#   2. All *non-whitelisted* files currently in OUTDIR are deleted, freeing slots.
#   3. New wallpapers are fetched to refill the pool up to LIMIT, skipping any ID
#      that is whitelisted or has ever been downloaded before (HISTORY_FILE).
# So whitelisted wallpapers are permanent; everything else rotates out every run
# and is never repeated (HISTORY_FILE is a permanent, ever-growing log of every
# ID seen so far — it is the "list" you download against).
#
set -euo pipefail

# ----------------------------- CONFIG --------------------------------------

API_KEY="${API_KEY:-}"           # your wallhaven API key (optional, needed for NSFW/account settings)
QUERY="${QUERY:-hot}"                         # search query, e.g. "nature", "-people", "@username"
CATEGORIES="${CATEGORIES:-100}"            # general/anime/people bitmask
PURITY="${PURITY:-111}"                    # sfw/sketchy/nsfw bitmask (nsfw needs API key)
SORTING="${SORTING:-date_added}"           # date_added, relevance, random, views, favorites, toplist
ORDER="${ORDER:-desc}"                     # desc, asc
TOPRANGE="${TOPRANGE:-1d}"                 # only used when SORTING=toplist: 1d,3d,1w,1M,3M,6M,1y
ATLEAST="${ATLEAST:-1920x1080}"                     # minimum resolution, e.g. "1920x1080"
RESOLUTIONS="${RESOLUTIONS:-2560x1440}"    # exact resolutions, e.g. "1920x1080,2560x1440"
RATIOS="${RATIOS:-16x9}"                       # aspect ratos, e.g. "16x9,16x10"
LIMIT="${LIMIT:-30}"                       # max wallpapers to keep in OUTDIR at once
MAX_SEARCH_PAGES="${MAX_SEARCH_PAGES:-30}" # safety cap on result pages to page through while refilling the pool
OUTDIR="${OUTDIR:-$HOME/Pictures/Wallpapers/wallhaven}"   # where to save downloaded images (tilde-safe: uses $HOME)
HISTORY_FILE="${HISTORY_FILE:-$OUTDIR/.history}"          # permanent record of every ID ever downloaded (never pruned)
WHITELIST_FILE="${WHITELIST_FILE:-$OUTDIR/.whitelist}"    # one wallpaper ID per line; pinned, survives rotation, auto-restored
BLACKLIST_FILE="${BLACKLIST_FILE:-$OUTDIR/.blacklist}"    # one wallpaper ID per line; never downloaded, deleted on sight
RATE_LIMIT_SLEEP="${RATE_LIMIT_SLEEP:-1.4}"               # seconds to sleep between API calls (45/min limit -> ~1.33s min)

# ---------------------------- ARG PARSING -----------------------------------

usage() {
  cat <<EOF
Usage: $0 [options]

  -q QUERY         search query (tags, -exclude, +required, @user, id:123, type:png, like:ID)
  -c CATEGORIES    categories bitmask, default $CATEGORIES (general/anime/people)
  -u PURITY        purity bitmask, default $PURITY (sfw/sketchy/nsfw)
  -s SORTING       date_added|relevance|random|views|favorites|toplist (default $SORTING)
  -o ORDER         desc|asc (default $ORDER)
  -t TOPRANGE      1d|3d|1w|1M|3M|6M|1y (used only with -s toplist, default $TOPRANGE)
  -r ATLEAST       minimum resolution, e.g. 1920x1080
  -R RESOLUTIONS   exact resolutions list, e.g. 1920x1080,2560x1440
  -a RATIOS        aspect ratios, e.g. 16x9,16x10
  -L LIMIT         max wallpapers kept in OUTDIR at once, default $LIMIT
  -d OUTDIR        output directory, default $OUTDIR
  -k API_KEY       wallhaven API key (or set API_KEY env var)
  -h               show this help

Whitelisting:
  Add a wallpaper ID (one per line) to the whitelist file to pin it — it will
  never be cleared during rotation, and will be re-downloaded automatically
  if its file goes missing. Whitelist file: \$OUTDIR/.whitelist (default)

Blacklisting:
  Add a wallpaper ID (one per line) to the blacklist file and it will never
  be downloaded again, and gets deleted on sight if already present.
  Blacklist file: \$OUTDIR/.blacklist (default)
  Note: this is per-ID and local only. Wallhaven's own account-level
  blacklist (tag_blacklist / user_blacklist, set on wallhaven.cc) is by tag
  or uploader, not by individual wallpaper — pass -k to apply it automatically.

Examples:
  $0                              # latest SFW wallpapers, keep pool of $LIMIT
  $0 -q "cyberpunk city" -L 15    # search a query, keep 15
  $0 -s toplist -t 1w             # weekly top wallpapers
EOF
  exit 1
}

while getopts "q:c:u:s:o:t:r:R:a:L:d:k:h" opt; do
  case "$opt" in
    q) QUERY="$OPTARG" ;;
    c) CATEGORIES="$OPTARG" ;;
    u) PURITY="$OPTARG" ;;
    s) SORTING="$OPTARG" ;;
    o) ORDER="$OPTARG" ;;
    t) TOPRANGE="$OPTARG" ;;
    r) ATLEAST="$OPTARG" ;;
    R) RESOLUTIONS="$OPTARG" ;;
    a) RATIOS="$OPTARG" ;;
    L) LIMIT="$OPTARG" ;;
    d) OUTDIR="$OPTARG" ;;
    k) API_KEY="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# If OUTDIR was overridden via -d after HISTORY_FILE/WHITELIST_FILE/BLACKLIST_FILE
# were computed from the old default, keep them consistent unless explicitly set.
HISTORY_FILE="${HISTORY_FILE:-$OUTDIR/.history}"
WHITELIST_FILE="${WHITELIST_FILE:-$OUTDIR/.whitelist}"
BLACKLIST_FILE="${BLACKLIST_FILE:-$OUTDIR/.blacklist}"

# ---------------------------- DEPENDENCY CHECK ------------------------------

for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Error: '$bin' is required but not installed." >&2; exit 1; }
done

mkdir -p "$OUTDIR"
touch "$HISTORY_FILE" "$WHITELIST_FILE" "$BLACKLIST_FILE"

# ---------------------------- HELPERS ---------------------------------------

urlencode() {
  jq -sRr @uri <<< "$1" | tr -d '\n'
}

api_call() {
  local url="$1"
  if [[ -n "$API_KEY" ]]; then
    curl -sS -H "X-API-Key: $API_KEY" "$url"
  else
    curl -sS "$url"
  fi
}

# id_of_file "path/to/94x38z.jpg" -> "94x38z"
id_of_file() {
  local base="${1##*/}"
  echo "${base%.*}"
}

# ---------------------------- STEP 1: RESTORE WHITELIST ---------------------

echo "== Checking whitelist for missing files =="
while IFS= read -r wid; do
  [[ -z "$wid" ]] && continue
  if ! compgen -G "${OUTDIR}/${wid}.*" > /dev/null; then
    echo "  [restore] $wid is whitelisted but missing, re-fetching..."
    info="$(api_call "https://wallhaven.cc/api/v1/w/${wid}")"
    path="$(echo "$info" | jq -r '.data.path // empty')"
    if [[ -z "$path" ]]; then
      echo "  [warn] could not fetch info for whitelisted ID $wid (deleted upstream or key required?)" >&2
    else
      ext="${path##*.}"
      curl -sS -o "${OUTDIR}/${wid}.${ext}" "$path"
      grep -qxF "$wid" "$HISTORY_FILE" || echo "$wid" >> "$HISTORY_FILE"
      echo "  [restored] $wid"
    fi
    sleep "$RATE_LIMIT_SLEEP"
  fi
done < "$WHITELIST_FILE"

# ---------------------------- STEP 1b: PURGE BLACKLIST -----------------------

echo "== Purging blacklisted wallpapers =="
purged=0
while IFS= read -r bid; do
  [[ -z "$bid" ]] && continue
  if grep -qxF "$bid" "$WHITELIST_FILE" 2>/dev/null; then
    echo "  [warn] $bid is in BOTH whitelist and blacklist — blacklist wins, removing." >&2
  fi
  for f in "${OUTDIR}/${bid}".*; do
    [[ -f "$f" ]] || continue
    rm -f "$f"
    purged=$((purged + 1))
    echo "  [purge] removed $bid"
  done
done < "$BLACKLIST_FILE"
echo "  purged $purged file(s)"

# ---------------------------- STEP 2: CLEAR NON-WHITELISTED ------------------

echo "== Rotating pool: clearing non-whitelisted wallpapers =="
cleared=0
for f in "$OUTDIR"/*; do
  [[ -f "$f" ]] || continue
  case "$f" in
    "$HISTORY_FILE"|"$WHITELIST_FILE"|"$BLACKLIST_FILE") continue ;;
  esac
  fid="$(id_of_file "$f")"
  if ! grep -qxF "$fid" "$WHITELIST_FILE" 2>/dev/null; then
    rm -f "$f"
    cleared=$((cleared + 1))
  fi
done
echo "  cleared $cleared file(s)"

whitelisted_present=$(find "$OUTDIR" -maxdepth 1 -type f \
  ! -name "$(basename "$HISTORY_FILE")" \
  ! -name "$(basename "$WHITELIST_FILE")" \
  ! -name "$(basename "$BLACKLIST_FILE")" \
  | wc -l | tr -d ' ')
slots_needed=$((LIMIT - whitelisted_present))
if (( slots_needed <= 0 )); then
  echo "Whitelist alone already fills or exceeds LIMIT ($LIMIT). Nothing new to fetch."
  exit 0
fi
echo "Need to fetch $slots_needed new wallpaper(s) to refill pool to $LIMIT."

# ---------------------------- STEP 3: FETCH NEW WALLPAPERS -------------------

downloaded=0
page=1

while (( downloaded < slots_needed )) && (( page <= MAX_SEARCH_PAGES )); do
  params="page=${page}&categories=${CATEGORIES}&purity=${PURITY}&sorting=${SORTING}&order=${ORDER}"
  [[ -n "$QUERY" ]]       && params="${params}&q=$(urlencode "$QUERY")"
  [[ "$SORTING" == "toplist" ]] && params="${params}&topRange=${TOPRANGE}"
  [[ -n "$ATLEAST" ]]     && params="${params}&atleast=${ATLEAST}"
  [[ -n "$RESOLUTIONS" ]] && params="${params}&resolutions=${RESOLUTIONS}"
  [[ -n "$RATIOS" ]]      && params="${params}&ratios=${RATIOS}"

  url="https://wallhaven.cc/api/v1/search?${params}"
  echo "-> Page $page: $url"

  response="$(api_call "$url")"

  if ! echo "$response" | jq -e '.data' >/dev/null 2>&1; then
    echo "Error: unexpected response on page $page:" >&2
    echo "$response" >&2
    sleep "$RATE_LIMIT_SLEEP"
    ((page++))
    continue
  fi

  last_page="$(echo "$response" | jq -r '.meta.last_page // 1')"
  count="$(echo "$response" | jq -r '.data | length')"

  if [[ "$count" -eq 0 ]]; then
    echo "No more results. Stopping."
    break
  fi

  while IFS=$'\t' read -r id path; do
    (( downloaded >= slots_needed )) && break

    # skip anything already downloaded before, pinned, or blacklisted
    if grep -qxF "$id" "$HISTORY_FILE" 2>/dev/null || grep -qxF "$id" "$WHITELIST_FILE" 2>/dev/null || grep -qxF "$id" "$BLACKLIST_FILE" 2>/dev/null; then
      continue
    fi

    ext="${path##*.}"
    outfile="${OUTDIR}/${id}.${ext}"
    echo "   [dl] $id -> $outfile"
    curl -sS -o "$outfile" "$path"
    echo "$id" >> "$HISTORY_FILE"
    downloaded=$((downloaded + 1))
    sleep "$RATE_LIMIT_SLEEP"
  done < <(echo "$response" | jq -r '.data[] | [.id, .path] | @tsv')

  if [[ "$page" -ge "$last_page" ]]; then
    echo "Reached last page ($last_page) of results."
    break
  fi

  ((page++))
  sleep "$RATE_LIMIT_SLEEP"
done

echo
echo "Done. Downloaded $downloaded new wallpaper(s). Pool now holds $((whitelisted_present + downloaded))/$LIMIT in $OUTDIR"

if (( downloaded < slots_needed )); then
  {
    echo
    echo "############################################################"
    echo "# ERROR: pool NOT fully refilled"
    echo "#   wanted:     $slots_needed new wallpaper(s)"
    echo "#   got:        $downloaded"
    echo "#   short by:   $((slots_needed - downloaded))"
    echo "#   ran out of new/unseen results (query too narrow, or"
    echo "#   HISTORY_FILE already covers everything matching it):"
    echo "#     QUERY:        '${QUERY}'"
    echo "#     HISTORY_FILE: $HISTORY_FILE"
    echo "#   Broaden the query, raise MAX_SEARCH_PAGES, or trim"
    echo "#   HISTORY_FILE to allow repeats."
    echo "############################################################"
  } >&2
  exit 1
fi
