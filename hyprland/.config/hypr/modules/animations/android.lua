-- ==============================================
-- ANDROID-LIKE ANIMATIONS
-- ==============================================

-- Beziers (fades, zoom e saídas)
hl.curve("android",     { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } })
hl.curve("androidIn",   { type = "bezier", points = { {0.3, 0.0}, {0.1, 1.0} } })
hl.curve("androidOut",  { type = "bezier", points = { {0.1, 0.0}, {0.3, 1.0} } })
hl.curve("androidSoft", { type = "bezier", points = { {0.35, 0.0}, {0.15, 1.0} } })
hl.curve("md3_accel",   { type = "bezier", points = { {0.3, 0.0}, {0.8, 0.15} } })
hl.curve("menu_accel",  { type = "bezier", points = { {0.38, 0.04}, {1.0, 0.07} } })
hl.curve("fadeSoft",    { type = "bezier", points = { {0.55, 0.0}, {0.85, 0.4} } })

-- Molas reais (mass = 1, exceto workspace; stiffness = velocidade; dampening = menos quique)
hl.curve("springWindow",    { type = "spring", mass = 1,   stiffness = 231.5, dampening = 21 })
hl.curve("springLayer",     { type = "spring", mass = 1,   stiffness = 264.6, dampening = 25.2 })
hl.curve("springWorkspace", { type = "spring", mass = 1.2, stiffness = 242.5, dampening = 27.7 })

-- Animações (speed é obrigatório, mas ignorado nas molas)
hl.animation({ leaf = "global",           enabled = true, speed = 4.76, bezier = "android" })

hl.animation({ leaf = "border",           enabled = false })
hl.animation({ leaf = "borderangle",      enabled = false })

hl.animation({ leaf = "fade",             enabled = true, speed = 3.33, bezier = "android" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 3.33, bezier = "androidOut" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 2.86, bezier = "androidIn" })
hl.animation({ leaf = "fadeSwitch",       enabled = true, speed = 2.38, bezier = "android" })
hl.animation({ leaf = "fadeDim",          enabled = true, speed = 2.38, bezier = "android" })

hl.animation({ leaf = "windows",          enabled = true, speed = 5,    spring = "springWindow", style = "slide" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5,    spring = "springWindow", style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.86, bezier = "md3_accel",    style = "slide" })

hl.animation({ leaf = "layers",           enabled = true, speed = 5,    spring = "springLayer", style = "slide" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 5,    spring = "springLayer", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2.38, bezier = "menu_accel",  style = "slide" })

hl.animation({ leaf = "fadeLayersIn",     enabled = false })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 2.38, bezier = "fadeSoft" })

hl.animation({ leaf = "workspaces",       enabled = true, speed = 5, spring = "springWorkspace", style = "slide" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 5, spring = "springWorkspace", style = "slidefade 80%" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 5, spring = "springWorkspace", style = "slidefade 40%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1, spring = "springWorkspace", style = "slidefadevert 40%" })

hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 3.81, bezier = "androidSoft" })
