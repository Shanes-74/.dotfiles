-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursor
hl.env("XCURSOR_SIZE", "26")
hl.env("HYPRCURSOR_SIZE", "26")

-- Toolkit backend
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("DESKTOP_SESSION", "hyprland")

-- XDG
--hl.env("XDG_CONFIG_HOME", "$HOME/.config")
--hl.env("XDG_CACHE_HOME", "$HOME/.cache")
--hl.env("XDG_DATA_HOME", "$HOME/.local/share")

-- GTK
hl.env("GTK_THEME", "m3-gtk")

-- QT
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_WAYLAND_SHELL_INTEGRATION", "xdg-shell")

--Native Apps & Toolkits
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Utils
hl.env("TERMINAL", "kitty")
hl.env("FILEMANAGER", "thunar")
hl.env("CLIPHIST_DB_PATH", "$XDG_RUNTIME_DIR/cliphist.db")

-- Intel
--hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("WLR_DRM_NO_ATOMIC", "1")
hl.env("__GL_GSYNC_ALLOWED", "0")
hl.env("__GL_VRR_ALLOWED", "0")

-- Nvidia
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("VDPAU_DRIVER", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("NVD_BACKEND", "direct")
