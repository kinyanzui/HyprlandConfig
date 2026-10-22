-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- All commands here run once when Hyprland starts,
-- equivalent to exec-once in the old .conf format.

hl.on("hyprland.start", function()
    -- Clipboard daemon (text + images)
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Udiskie
    hl.exec_cmd("udiskie")

    -- Dark Mode
    hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "YOUR_DARK_GTK3_THEME"')
    hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
    hl.exec_cmd('dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME')

    -- Hyprsunset (started as a service, hence commented out.)
    -- systemctl --user enable --now hyprsunset.service
    hl.exec_cmd('hyprsunset')

    hl.exec_cmd('waybar')
    -- Hyprlock
    hl.exec_cmd('hyprlock')

    -- swayosd server
    hl.exec_cmd('swayosd-server')

    -- swaync
    hl.exec_cmd('swaync')


    -- Autostart for wallpapers.
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper.sh start")


    -- Autostart for battery monitor.
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/battery-monitor.sh start")
    --
    hl.on("hyprland.start", function()
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)



end)
