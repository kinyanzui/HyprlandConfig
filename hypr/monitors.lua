------------------
---- MONITORS ----
------------------

-- Primary Laptop Display (enabled by default)
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
    disabled = false,
})

-- My monitor, MSI
hl.monitor({
    output   = "desc:Microstep MAG 255F E20 BC2M506300578",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = "auto",
})

-- The TV at home, Haier
hl.monitor({
    output   = "desc:Qingdao Haier Electronics Co. Ltd. Haier TV 0x00000001",
    mode     = "4096x2160@30",
    position = "auto",
    scale    = 2.67,
})

-- Fallback for external/unspecified monitors
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


-----------------------------
---- LID / DOCK HANDLING ----
-----------------------------

-- All the logic lives in scripts/set-display.sh: <monitor> <on|off|rescue>
local script = os.getenv("HOME") .. "/.config/hypr/scripts/set-display.sh eDP-1 "

-- Lid closed: disable the laptop panel, but only if another monitor is connected
-- (otherwise the script locks the screen instead of blanking everything).
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(script .. "off"), { locked = true })

-- Lid opened: bring the laptop panel back.
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(script .. "on"),  { locked = true })

-- A monitor disappeared (unplugged, or eDP-1 itself was just disabled).
-- "rescue" only re-enables eDP-1 if NO monitor is active, so it can't
-- fight the lid-close handler above.
hl.on("monitor.removed", function()
    hl.exec_cmd(script .. "rescue")
end)


hl.bind("SUPER + F12",         hl.dsp.exec_cmd(script .. "off"))
hl.bind("SUPER + SHIFT + F12", hl.dsp.exec_cmd(script .. "on"))
