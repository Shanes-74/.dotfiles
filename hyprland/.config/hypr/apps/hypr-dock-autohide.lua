-- ~/.config/hypr/hyprland.lua

-- 1. Configuração do Dock
DockConfig = {
    edge = "bottom",
    activate_zone = 5,
    hide_delay = 10,
    activation_width = 400,
    dodge = 0
}

-- 2. Função para enviar comandos ao daemon Go
local socket_path = "/tmp/hypr-dock-autohide.sock"

local function send_to_dock(command)
    local client = require("socket.unix")
    local s, err = client.connect(socket_path)
    if not s then
        print("Erro ao conectar ao daemon do dock:", err)
        return
    end
    s:send(command .. "\n")
    s:close()
end

-- 3. Inicia o daemon (você pode usar `exec-once` em vez disso)
-- os.execute("hypr-dock-autohide &")

-- ~/.config/hypr/hyprland.lua (continuação)

local hide_timer = nil
local dock_visible = false

local function show_dock()
    if not dock_visible then
        send_to_dock("show")
        dock_visible = true
    end
end

local function hide_dock()
    if dock_visible then
        send_to_dock("hide")
        dock_visible = false
        if hide_timer then
            hide_timer:stop()
            hide_timer = nil
        end
    end
end

-- Monitora o movimento do mouse para detectar a zona de ativação
hl.on("mouse.move", function(pos)
    local mon = hl.monitor.focused()
    if not mon then return end
    
    -- Lógica simplificada de verificação da borda
    if DockConfig.edge == "bottom" and pos.y >= mon.y + mon.h - DockConfig.activate_zone then
        show_dock()
        if hide_timer then hide_timer:stop() end
        hide_timer = hl.timer(DockConfig.hide_delay * 100, function()
            hide_dock()
        end)
    end
end)

-- Monitora quando uma janela é focada para esconder o dock (modo dodge)
hl.on("window.active", function(w)
    if DockConfig.dodge == 1 then
        hide_dock()
    end
end)

-- Recarrega a configuração
hl.on("config.reloaded", function()
    -- Aqui você poderia ler as novas configurações e enviar para o daemon
    send_to_dock("reload")
end)

package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"os/exec"
	"strings"
)

const socketPath = "/tmp/hypr-dock-autohide.sock"

func main() {
	// Limpa socket anterior
	os.Remove(socketPath)

	l, err := net.Listen("unix", socketPath)
	if err != nil {
		panic(err)
	}
	defer l.Close()

	fmt.Println("Daemon do dock ouvindo em", socketPath)

	for {
		conn, err := l.Accept()
		if err != nil {
			continue
		}
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		cmd := strings.TrimSpace(scanner.Text())
		switch cmd {
		case "show":
			exec.Command("hypr-dock", "--show").Run() // ou como seu dock funciona
		case "hide":
			exec.Command("hypr-dock", "--hide").Run()
		case "reload":
			// Recarrega sua config interna se necessário
			fmt.Println("Recarregando configuração...")
		default:
			fmt.Println("Comando desconhecido:", cmd)
		}
	}
}