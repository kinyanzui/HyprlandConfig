------------------------------
---- ENVIRONMENT VARIABLES ----
------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursor
hl.env("XCURSOR_SIZE",    "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- NOTE: First install the required package using pacman.
-- sudo pacman -S gnome-themes-extra
--
-- Then proceed to run the command below:
-- gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"


-- Dark mode
hl.env("GTK_THEME",        "Adwaita:dark")
hl.env("GTK2_RC_FILES",    "/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc")
hl.env("QT_STYLE_OVERRIDE", "Adwaita-Dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- Editor
hl.env("EDITOR", "nvim")
