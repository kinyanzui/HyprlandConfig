------------------
---- MONITORS ----
------------------

-- The laptop panel is the primary display. It is always on and is never disabled,
-- not on lid close and not when an external monitor is connected.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
    disabled = false,
})

-- Every external monitor mirrors eDP-1.
-- Scale is irrelevant for a mirror, so it stays at 1.

-- My monitor, MSI
hl.monitor({
    output   = "desc:Microstep MAG 255F E20 BC2M506300578",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = 1,
    mirror   = "eDP-1",
})

-- The TV at home, Haier
hl.monitor({
    output   = "desc:Qingdao Haier Electronics Co. Ltd. Haier TV 0x00000001",
    mode     = "4096x2160@30",
    position = "auto",
    scale    = 1,
    mirror   = "eDP-1",
})

-- Fallback for any other external monitor (must stay last)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
    mirror   = "eDP-1",
})


--------------------------
---- MIRROR SAFETY NET ----
--------------------------

-- The rules above already mirror known monitors. This hook re-applies the mirror
-- (and makes sure eDP-1 is on) whenever a monitor is plugged in, so a monitor
-- the rules didn't catch still ends up mirrored.
-- Logic lives in scripts/set-display.sh: <monitor> <mirror|ensure>
local script = os.getenv("HOME") .. "/.config/hypr/scripts/set-display.sh eDP-1 "

hl.on("monitor.added", function()
    hl.exec_cmd(script .. "mirror")
end)

-- There is deliberately no lid-switch handling here. Closing the lid does nothing
-- to the display layout; logind decides whether the machine suspends
-- (HandleLidSwitchDocked=ignore in /etc/systemd/logind.conf keeps it awake).
