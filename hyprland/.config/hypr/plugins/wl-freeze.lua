-- wl-freeze: janela suspensa fica translúcida e dessaturada

hl.window_rule({
    name = "frozen-window",
    match = { tag = "frozen" },
    opaque = true,
    no_blur = true,
})

if hl.plugin.darkwindow ~= nil then
    hl.plugin.darkwindow.load_shader("frozen", {
        source = [[
            void windowShader(inout vec4 color) {
                float l = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
                color.rgb = mix(color.rgb, vec3(l), x_FadeIn);
                color.rgb *= 1.0 - 0.5 * x_FadeIn;
            }
        ]],
        fade_in_speed = 3,
        fade_out_speed = 3,
    })

    hl.window_rule({
        name = "frozen-shader",
        match = { tag = "frozen" },
        ["darkwindow:shade"] = "frozen",
    })
end

hl.bind("CTRL + SUPER + P", function()
    hl.dispatch(hl.dsp.window.tag({ tag = "frozen" }))
    hl.dispatch(hl.dsp.exec_cmd("wl-freeze -a"))
end)
