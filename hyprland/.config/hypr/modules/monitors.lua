------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "auto",
    scale    = "1",
})

hl.monitor({
	output   = "HDMI-A-2",
	mode     = "1600x900@60Hz",
	position = "auto",
	scale	 = "0.83",
})

-- Workspaces 1-4 on main monitor
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = false })
hl.workspace_rule({ workspace = "6", monitor = "eDP-1", persistent = false })
-- Workspaces 7-10 on a secondary monitor
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-2", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2", persistent = true })
