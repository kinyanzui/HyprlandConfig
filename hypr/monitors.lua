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


-- The TV at home, MSI
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

local function external_connected()
    local p = io.popen("cat /sys/class/drm/card*-DP-*/status /sys/class/drm/card*-HDMI-A-*/status 2>/dev/null")
    if not p then return false end
    local s = p:read("*a") or ""
    p:close()
    -- exact "connected" lines only, not "disconnected"
    return s:find("^connected") ~= nil or s:find("\nconnected") ~= nil
end

local function lid_is_closed()
    local p = io.popen("cat /proc/acpi/button/lid/*/state")
    if not p then return false end
    local s = p:read("*a") or ""
    p:close()
    return s:find("closed") ~= nil
end

local internal_on = true  -- last state we applied (nil = unknown)

local function set_internal(enabled)
    if internal_on == enabled then return end   -- guard against event loops
    internal_on = enabled
    if enabled then
        hl.monitor({
            output   = "eDP-1",
            mode     = "preferred",
            position = "0x0",
            scale    = 1,
            disabled = false,
        })
    else
        hl.monitor({ output = "eDP-1", disabled = true })
    end
end

-- Disable the laptop screen only when: lid closed AND an external is connected
local function apply_lid_state()
    set_internal(not (lid_is_closed() and external_connected()))
end

local function apply_soon()
    hl.timer(apply_lid_state, { timeout = 500, type = "oneshot" })
end

hl.bind("switch:on:Lid Switch",  apply_lid_state, { locked = true })
hl.bind("switch:off:Lid Switch", apply_lid_state, { locked = true })

hl.on("monitor.added",   apply_soon)
hl.on("monitor.removed", apply_soon)

-- startup / reload
hl.timer(apply_lid_state, { timeout = 1500, type = "oneshot" })
