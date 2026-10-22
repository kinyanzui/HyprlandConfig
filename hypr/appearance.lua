-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
-- Noctalia-specific values: https://docs.noctalia.dev/v4/getting-started/compositor-settings/hyprland/

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,  -- noctalia recommends 10

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 20,  -- noctalia recommends 20
        rounding_power = 2,

        -- Window transparency (overridden to 1.0 for fullscreen — see window rule below)
        active_opacity   = 0.85,  -- focused windows
        inactive_opacity = 0.70,  -- unfocused windows

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,  -- rgba(1a1a1aee)
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 2,      -- noctalia recommends 2 for panel blur
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})


--------------------
---- CURVES ---------
--------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })


----------------------
---- ANIMATIONS ------
----------------------

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default"      })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy"         })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick"        })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick"        })


-------------------
---- LAYOUTS ------
-------------------

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-- "Smart gaps" / "No gaps when only" — uncomment to enable
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })


----------------
---- MISC -------
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


------------------------------
---- SWAYNC LAYER RULE ------
------------------------------

-- Enables blur on the Noctalia bar and panel backgrounds.
-- Adjust ignore_alpha alongside Noctalia's panel/bar opacity settings
-- to dial in the blur look. See: https://docs.noctalia.dev/v4/getting-started/compositor-settings/hyprland/#blur
--

   hl.layer_rule({
       name  = "swaync",
       match = { namespace = "swaync-(control-center|notification-window)$" },

       ignore_alpha = 0.5,
       blur         = true,
       blur_popups  = true,
   })


--------------------------
---- WINDOW RULES --------
--------------------------

-- Restore full opacity in fullscreen so transparency doesn't interfere
-- with video, games, or any maximised app.
hl.window_rule({
    name  = "fullscreen-opaque",
    match = { fullscreen = true },

    opacity = "1.0 override 1.0 override",
})

-- Satty: open floating and centered so it overlays your current workspace
-- without disrupting the tiling layout. Drag it anywhere after it opens.
-- Class regex covers both "satty" and "com.gabm.satty" app-ids.
hl.window_rule({
    name   = "float-satty",
    match  = { class = "com.gabm.satty" },

    float  = true,
    center = true,
    size = "1200 700"
})

-- Picture-in-Picture: auto-float, pin across all workspaces, and lock to
-- a small 400×225 (16:9) size in the bottom-right corner of the screen.
-- You can still drag it wherever you like — pin just keeps it visible
-- on every workspace.
hl.window_rule({
    name  = "pip-float-pin",
    match = { title = "^Picture-in-Picture$" },

    float  = true,
    pin    = true,
    size   = "400 225",
    move   = "75% 75%",
})
