-- ==============================================
-- MACOS-LIKE ANIMATIONS
-- ==============================================

-- Curvas Bezier
hl.curve("md3_decel",  { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel",  { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })

-- Curvas Spring
hl.curve("spring_menu",     { type = "spring", mass = 1,   stiffness = 80, dampening = 14 })
hl.curve("spring_window",   { type = "spring", mass = 1,   stiffness = 35, dampening = 8 })
hl.curve("spring_open",     { type = "spring", mass = 1,   stiffness = 35, dampening = 8 })
hl.curve("spring_workspace",{ type = "spring", mass = 1.2, stiffness = 35, dampening = 10 })
hl.curve("spring_special",  { type = "spring", mass = 1,   stiffness = 35, dampening = 8 })

-- Animações
hl.animation({ leaf = "windows",          enabled = true, speed = 1, spring = "spring_window" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 1, spring = "spring_open", style = "popin 40%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3, bezier = "md3_accel", style = "popin 60%" })

hl.animation({ leaf = "border",           enabled = false })
hl.animation({ leaf = "borderangle",      enabled = false })

hl.animation({ leaf = "fade",             enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 6, bezier = "md3_decel" })

hl.animation({ leaf = "layersIn",         enabled = true, speed = 3, spring = "spring_menu", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.6, bezier = "menu_accel", style = "slide" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 1.6, bezier = "menu_accel" })

hl.animation({ leaf = "workspaces",       enabled = true, speed = 1, spring = "spring_workspace", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1, spring = "spring_special", style = "slidefadevert 40%" })