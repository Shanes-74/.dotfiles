-- ~/.config/hypr/lua/dock-autohide.lua
-- "Windows can cover" para nwg-dock-hyprland
-- Suporte a janelas flutuantes, PID direto (sem pkill -f), tolerância de overlap,
-- e kill total em fullscreen real (tipo 2).

local DOCK_NAMESPACE = "nwg-dock"
local DOCK_MONITOR = nil
local WINDOW_POLL_MS = 500 -- aumentado para reduzir CPU

-- Janela pode chegar até esse tanto (px) mais perto da dock antes de contar como
-- "encostando" nela. Compensa a dock esconder visualmente antes da janela tocar de fato.
local OVERLAP_MARGIN = 25

-- Caminho absoluto do launcher (não confia no PATH do ambiente do Hyprland).
local NWG_DOCK_BIN = os.getenv("HOME") .. "/.local/bin/nwg-dock"

local cachedDockFootprint = 76 + 30 -- bootstrap grosseiro, corrigido na primeira medição real
local cachedDockPid = nil
local forcedVisible = false
local dockKilled = false -- true quando A GENTE matou de propósito por causa de fullscreen tipo 2

-- Obtém o monitor onde a dock está (ou o ativo como fallback)
local function getDockMonitor()
	if DOCK_MONITOR then
		return hl.get_monitor(DOCK_MONITOR)
	end
	for _, mon in ipairs(hl.get_monitors()) do
		local layers = hl.get_layers({ monitor = mon.name, namespace = DOCK_NAMESPACE })
		if layers and #layers > 0 then
			return mon
		end
	end
	return hl.get_active_monitor()
end

-- Mede a altura real da dock e guarda o pid atual, sempre que a layer existir.
local function dockFootprint(layers)
	if layers and #layers > 0 then
		cachedDockPid = layers[1].pid
		local measured = layers[1].h
		if measured ~= cachedDockFootprint then
			cachedDockFootprint = measured
		end
	end
	return cachedDockFootprint
end

-- Retângulo real usado pra detecção de overlap, encolhido por OVERLAP_MARGIN
-- a partir do topo (janela precisa entrar mais fundo antes de contar como "encostando").
local function dockRect(mon, footprint)
	local h = footprint - OVERLAP_MARGIN
	return {
		x = mon.x,
		y = mon.y + mon.height - h,
		w = mon.width,
		h = h,
	}
end

-- Verifica se alguma janela (tileada ou flutuante) intersecta a área da dock
local function dockAreaOccupied(mon, footprint)
	local ws = mon.active_workspace
	if not ws then
		return false
	end
	local dock = dockRect(mon, footprint)
	for _, w in ipairs(ws:get_windows()) do
		if
			w.at.x < dock.x + dock.w
			and w.at.x + w.size.x > dock.x
			and w.at.y < dock.y + dock.h
			and w.at.y + w.size.y > dock.y
		then
			return true
		end
	end
	return false
end

-- Só true se houver janela em fullscreen "de verdade" (tipo 2) no workspace ativo.
-- Tipo 1 (maximizado) não conta — a dock continua se comportando normal nesse caso.
local function hasRealFullscreen(mon)
	local ws = mon.active_workspace
	if not ws then
		return false
	end
	for _, w in ipairs(ws:get_windows()) do
		if w.fullscreen == 2 then
			return true
		end
	end
	return false
end

-- Manda sigShow/sigHide pelo pid em cache (rápido, sem varrer /proc); cai pra
-- pkill -f só se ainda não tivermos um pid conhecido (ex.: logo após o boot).
local function sendSignal(sig)
	if cachedDockPid then
		hl.exec_cmd("kill -s RTMIN+" .. sig .. " " .. cachedDockPid)
	else
		hl.exec_cmd("pkill -RTMIN+" .. sig .. " -f nwg-dock-hyprland")
	end
end

local function evaluate()
	local mon = getDockMonitor()
	if not mon then
		return
	end

	-- Fullscreen tipo 2: mata a dock inteira (inclusive o hotspot do -d), pra
	-- não ter como reaparecer nem passando o mouse no canto.
	if hasRealFullscreen(mon) then
		if not dockKilled then
			hl.exec_cmd("killall nwg-dock-hyprland")
			dockKilled = true
			forcedVisible = false
			cachedDockPid = nil
		end
		return
	elseif dockKilled then
		hl.exec_cmd(NWG_DOCK_BIN .. " &")
		dockKilled = false
		-- segue o fluxo normal abaixo; a layer ainda não existe nesse tick, tudo bem
	end

	local layers = hl.get_layers({ monitor = mon.name, namespace = DOCK_NAMESPACE })
	local mapped = layers and #layers > 0
	local footprint = dockFootprint(layers)
	local occupied = dockAreaOccupied(mon, footprint)

	if occupied then
		if forcedVisible then
			sendSignal(3) -- sigHide
			forcedVisible = false
		end
	else
		if not mapped then
			sendSignal(2) -- sigShow
		end
		forcedVisible = true
	end
end

-- Eventos
hl.on("window.open", evaluate)
hl.on("window.close", evaluate)
hl.on("window.move_to_workspace", evaluate)
hl.on("window.fullscreen", evaluate)
hl.on("workspace.active", evaluate)
hl.on("monitor.focused", evaluate)

hl.on("layer.closed", function(layer)
	if layer and layer.namespace == DOCK_NAMESPACE then
		evaluate()
	end
end)

-- Polling para movimentação/redimensionamento de janelas
hl.timer(evaluate, { timeout = WINDOW_POLL_MS, type = "repeat" })