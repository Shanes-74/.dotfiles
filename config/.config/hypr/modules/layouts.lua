hl.config({general = {layout = "scrolling",},})

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "slave",
        new_on_active = "before",
        mfact = 0.6,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        follow_focus = true,
        follow_min_visible = 0.0,
        focus_fit_method = 1,
        column_width = 0.70,
        explicit_column_widths = 0.25, 0.5, 0.75, 1.0,
    },
})