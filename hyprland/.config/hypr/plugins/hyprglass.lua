if hl.plugin.hyprglass ~= nil then
    local hg = hl.plugin.hyprglass

    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 1.0,
        dark = { brightness = 0.82 },
        light = { brightness = 1.2 },
    })

    hg.preset("contrasted", {
        inherits = "high_contrast",
        contrast = 1.2,
        adaptive_dim = 1.0,
        dark = { tint_color = 0x02142aa9 },
    })

    local colors = require("modules.colors")
    local function tint(c, alpha)
    return tonumber(c:match("%x%x%x%x%x%x"), 16) * 256
        + math.floor(alpha * 255 + 0.5)
    end

    hg.preset("glass", {
        blur_strength = 3.8,
        blur_iterations = 3.8,
        chromatic_aberration = 0.05,
        fresnel_strength = 0.2,
        edge_thickness = 0.02,
        tint_color = tint(colors.surface, 0.12),
        lens_distortion = 0.2,
        brightness = 1.0,
        contrast = 1.2,
        saturation = 1,
        vibrancy = 0.8,
        vibrancy_darkness = 1,
        adaptive_boost = 0.5
    })

    -- Preset principal: réplica do Liquid Glass do macOS
    hg.preset("apple", {
        blur_strength        = 2.2,  -- frosted mas ainda deixa ver o fundo
        blur_iterations       = 3,
        refraction_strength  = 0.55, -- a "curvatura" nas bordas é a marca registrada do efeito
        chromatic_aberration = 0.3, -- franja de cor sutil, sem exagero
        fresnel_strength     = 0.5,  -- glow na borda
        specular_strength    = 0.75,  -- highlight forte no topo, bem típico do macOS
        edge_thickness       = 0.05,  -- bezel mais espesso pra dar espaço à lente
        lens_distortion      = 0.3, -- magnificação central (efeito "gota líquida")

        dark = {
            brightness     = 0.82,
            contrast       = 0.90,
            saturation     = 0.80,
            vibrancy       = 0.15,
            adaptive_dim   = 0.40,
        },
        light = {
            brightness     = 1.12,
            contrast       = 0.92,
            saturation     = 0.85,
            vibrancy       = 0.12,
            adaptive_boost = 0.40,
        },
    })

    local mask = 0.5

    hg.layer("waybar", { mask_threshold = mask })
    hg.layer("swaync-control-center", { mask_threshold = mask })
    hg.layer("swaync-notification-window", { mask_threshold = mask })
    hg.layer("rofi", { mask_threshold = mask })
	hg.layer("nwg-dock", { mask_threshold = mask })

    --hl.window_rule({ match = { class = "kitty"}, tag = "+hyprglass_enabled"})
    --hl.window_rule({ match = { class = "zen"}, tag = "+hyprglass_enabled"})

    hg.config({
        enabled = true,
        default_theme = "light",
        default_preset = "glass",
        layers = { enabled = true },
    })
end
