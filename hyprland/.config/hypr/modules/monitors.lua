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
	output   = "DP-1",
	mode     = "preferred",
	position = "auto",
	scale	 = "1.25"
})

-- Workspaces 1-5 on main monitor
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true })
--hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true })
