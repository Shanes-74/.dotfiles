-- ==============================================
-- ANDROID-LIKE ANIMATIONS
-- ==============================================

-- Curvas Bezier
hl.curve("android",     { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } })
hl.curve("androidIn",   { type = "bezier", points = { {0.3, 0.0}, {0.1, 1.0} } })
hl.curve("androidOut",  { type = "bezier", points = { {0.1, 0.0}, {0.3, 1.0} } })
hl.curve("androidSoft", { type = "bezier", points = { {0.35, 0.0}, {0.15, 1.0} } })
hl.curve("springIn",    { type = "bezier", points = { {0.18, 0.89}, {0.32, 1.10} } })
hl.curve("springOut",   { type = "bezier", points = { {0.6, -0.10}, {0.73, 0.05} } })
hl.curve("default",     { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } }) -- curva padrão do Hyprland

-- Animações
hl.animation({ leaf = "global",        enabled = true, speed = 4, bezier = "android" })
hl.animation({ leaf = "border",        enabled = true, speed = 3, bezier = "default" })

hl.animation({ leaf = "windows",       enabled = true, speed = 4, bezier = "android",      style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3, bezier = "springIn",     style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 4, bezier = "springOut",    style = "slide" })

hl.animation({ leaf = "fade",          enabled = true, speed = 3, bezier = "android" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 2, bezier = "springIn" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 3, bezier = "springOut" })

hl.animation({ leaf = "layers",        enabled = true, speed = 3, bezier = "android",      style = "slide" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3, bezier = "springIn",     style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3, bezier = "springOut",    style = "slide" })

hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2, bezier = "springIn" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3, bezier = "springOut" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 4, bezier = "androidSoft",  style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3, bezier = "springIn",     style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "springOut",    style = "slide" })

hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 3, bezier = "springIn" })