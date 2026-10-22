---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local programs = require("programs")
local mainMod  = "SUPER" -- Sets "Windows" key as main modifier


-- ── System ────────────────────────────────────────────────────────────────────

hl.bind(mainMod .. " + Q",         hl.dsp.window.close())


-- ── Apps ──────────────────────────────────────────────────────────────────────

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(programs.browser))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(programs.codeEditor))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(programs.music))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.terminal .. " " .. programs.fileManager))

-- App launcher using rofi.
-- NOTE: NOTE: Figure out toggling by pressing the same keys.
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(programs.launcher))

hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(programs.lock))

-- TODO: This isn't done. Should be attended to.
-- Clipboard history (cliphist + rofi): text and images.
-- Needs the wl-paste watchers from the autostart section to be running.
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/rofi/cliphist.sh"))


-- ── Screenshots ───────────────────────────────────────────────────────────────

-- Flow:
--   1. slurp   → draw a region on screen
--   2. grim    → capture that region to a temp file
--   3. wl-copy → immediately copy to clipboard (it's already there when satty opens)
--   4. satty   → annotation window — draw, highlight, save, or copy the edited version
--
-- Requires: grim, slurp, satty, wl-clipboard
-- sudo pacman -S grim slurp satty wl-clipboard
-- Install satty: https://github.com/gabm/satty


-- Screenshots
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(
    [[sh -c 'DIR=~/Pictures/screenshots && mkdir -p "$DIR" && FILE="$DIR/screenshot_$(date +%Y%m%d_%H%M%S).png" && grim -g "$(slurp)" "$FILE" && wl-copy < "$FILE" && notify-send -i "$FILE" "Screenshot" "Copied to clipboard." && satty --filename "$FILE" --copy-command "wl-copy"']]
))

hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(
    [[sh -c 'grim -g "$(slurp)" /tmp/ocr.png && tesseract /tmp/ocr.png /tmp/ocr && wl-copy < /tmp/ocr.txt && notify-send "OCR Screenshot" "Text extracted to clipboard" && rm /tmp/ocr.png /tmp/ocr.txt']]
))


-- ── Power Profile ──────────────────────────────────────────────────────────
hl.bind(mainMod .. " + ALT + P", function()
    hl.exec_cmd("powerprofilesctl set performance")
end)

hl.bind(mainMod .. " + ALT + B", function()
    hl.exec_cmd("powerprofilesctl set balanced")
end)

hl.bind(mainMod .. " + ALT + S", function()
    hl.exec_cmd("powerprofilesctl set power-saver")
end)


-- ── Window management ─────────────────────────────────────────────────────────

hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + I", hl.dsp.window.pin())
hl.bind(mainMod .. " + Z", hl.dsp.window.pseudo())       -- dwindle pseudotile toggle

-- Float + Pin in one shot - useful for PiP or any window you want
-- to keep floating above everything else across all workspaces.
-- SUPER + SHIFT + D -> make active window float and pin it.
-- SUPER + SHIFT + D again -> unpin and return to tiling.
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(
    "hyprctl --batch 'dispatch togglefloating ; dispatch pin'"
))


-- Move focus — vim keys
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down"  }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- ── Workspaces ────────────────────────────────────────────────────────────────

-- Switch to workspace 1–9, and 0 → workspace 10
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0",         hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))


-- Cycle through workspaces - vim keys
hl.bind(mainMod .. " + CONTROL + l", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CONTROL + h",  hl.dsp.focus({ workspace = "e-1" }))


-- Move active window to adjacent workspace (and follow)
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + h",  hl.dsp.window.move({ workspace = "e-1" }))

-- Scratchpad (special workspace)
-- NOTE: moved from SHIFT+S → CTRL+S to free up SHIFT+S for screenshots
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))


-- ── Media & hardware keys ─────────────────────────────────────────────────────
-- NOTE: Ensure you have swayosd installed, and autostart its server
-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5"),    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"),    { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),   { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness +5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -5"), { locked = true, repeating = true })

-- Playback (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("swayosd-client --playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("swayosd-client --playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("swayosd-client --playerctl play"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl pause"), { locked = true })
-- Find a bind that'll act as a toggle for both play and pause.


-- ── Wallpaper ─────────────────────────────────────────────────────────────────
-- Cycling and the 10-minute auto-switch are handled by scripts/wallpaper.sh
-- (started from hyprpaper.lua). Manual changes also reset its timer.
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd(programs.changeWallpaper))  -- next wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(programs.pickWallpaper))    -- rofi picker
