package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

const (
	pollInterval = 50 * time.Millisecond
	pidFile      = "/tmp/hypr-dock-autohide.pid"
)

// ──────────────── Config ────────────────

type Config struct {
	Edge            string `json:"edge"`
	ActivateZone    int    `json:"activate_zone"`
	HideDelay       int    `json:"hide_delay"`
	ActivationWidth int    `json:"activation_width"`
	Dodge           int    `json:"dodge"`
}

func defaultConfig() Config {
	return Config{
		Edge:            "bottom",
		ActivateZone:    5,
		HideDelay:       10,
		ActivationWidth: 400,
		Dodge:           0,
	}
}

func loadConfig(path string) Config {
	cfg := defaultConfig()
	f, err := os.Open(path)
	if err != nil {
		return cfg
	}
	defer f.Close()
	json.NewDecoder(f).Decode(&cfg)
	return cfg
}

// ──────────────── Geometria ────────────────

type Pos struct{ X, Y int }
type Rect struct {
	X, Y, W, H int
	Found      bool
}

func (r Rect) Contains(p Pos) bool {
	return r.Found && p.X >= r.X && p.X < r.X+r.W && p.Y >= r.Y && p.Y < r.Y+r.H
}

type Monitor struct {
	X, Y, Width, Height int
	Focused             bool
}

type Client struct {
	At        [2]int `json:"at"`
	Size      [2]int `json:"size"`
	Workspace struct {
		ID int `json:"id"`
	} `json:"workspace"`
	Hidden     bool `json:"hidden"`
	Mapped     bool `json:"mapped"`
	Fullscreen int  `json:"fullscreen"`
}

func inEdgeZone(p Pos, edge string, zone int, mon Monitor) bool {
	switch edge {
	case "bottom":
		return p.Y >= mon.Y+mon.Height-zone
	case "top":
		return p.Y <= mon.Y+zone
	case "left":
		return p.X <= mon.X+zone
	case "right":
		return p.X >= mon.X+mon.Width-zone
	}
	return false
}

func inEdgeCenter(p Pos, edge string, lo, hi int) bool {
	switch edge {
	case "bottom", "top":
		return p.X >= lo && p.X <= hi
	case "left", "right":
		return p.Y >= lo && p.Y <= hi
	}
	return false
}

func popupDepth(edge string, popup Rect, mon Monitor) int {
	switch edge {
	case "bottom":
		return mon.Y + mon.Height - popup.Y
	case "top":
		return popup.Y + popup.H - mon.Y
	case "left":
		return mon.X + mon.Width - popup.X
	case "right":
		return popup.X + popup.W - mon.X
	}
	return 0
}

func centerBand(mon Monitor, activationWidth int) (lo, hi int) {
	lo = mon.X + (mon.Width-activationWidth)/2
	hi = lo + activationWidth
	return
}

func cursorOnMonitor(p Pos, mon Monitor) bool {
	return p.X >= mon.X && p.X < mon.X+mon.Width &&
		p.Y >= mon.Y && p.Y < mon.Y+mon.Height
}

func anyFullscreen(clients []Client, wsID int) bool {
	for _, c := range clients {
		if c.Workspace.ID == wsID && c.Fullscreen > 0 {
			return true
		}
	}
	return false
}

// ──────────────── IPC ────────────────

func socketPath(name string) string {
	sig := os.Getenv("HYPRLAND_INSTANCE_SIGNATURE")
	if sig == "" {
		log.Fatal("HYPRLAND_INSTANCE_SIGNATURE não definida")
	}
	runtime := os.Getenv("XDG_RUNTIME_DIR")
	if runtime == "" {
		runtime = "/tmp"
	}
	return filepath.Join(runtime, "hypr", sig, name)
}

func hyprRequest(msg string) ([]byte, error) {
	conn, err := net.Dial("unix", socketPath(".socket.sock"))
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(2 * time.Second))
	if _, err = conn.Write([]byte(msg)); err != nil {
		return nil, err
	}
	var buf []byte
	tmp := make([]byte, 4096)
	for {
		n, err := conn.Read(tmp)
		if n > 0 {
			buf = append(buf, tmp[:n]...)
		}
		if err != nil {
			break
		}
	}
	return buf, nil
}

func getCursorPos() (Pos, error) {
	data, err := hyprRequest("j/cursorpos")
	if err != nil {
		return Pos{}, err
	}
	var p Pos
	err = json.Unmarshal(data, &p)
	return p, err
}

func getMonitors() ([]Monitor, error) {
	data, err := hyprRequest("j/monitors")
	if err != nil {
		return nil, err
	}
	var mons []Monitor
	err = json.Unmarshal(data, &mons)
	return mons, err
}

func getFocusedMonitor() (Monitor, error) {
	mons, err := getMonitors()
	if err != nil {
		return Monitor{}, err
	}
	for _, m := range mons {
		if m.Focused {
			return m, nil
		}
	}
	return Monitor{}, fmt.Errorf("nenhum monitor focado")
}

func getActiveWorkspaceID() int32 {
	data, err := hyprRequest("j/activeworkspace")
	if err != nil {
		return 1
	}
	var ws struct {
		ID int32 `json:"id"`
	}
	json.Unmarshal(data, &ws)
	return ws.ID
}

func getClients() ([]Client, error) {
	data, err := hyprRequest("j/clients")
	if err != nil {
		return nil, err
	}
	var clients []Client
	err = json.Unmarshal(data, &clients)
	return clients, err
}

// ──────────────── Camadas (cache) ────────────────

type LayerCache struct {
	mu          sync.Mutex
	dock, popup Rect
	dirty       bool
}

func (c *LayerCache) markDirty() {
	c.mu.Lock()
	c.dirty = true
	c.mu.Unlock()
}

func (c *LayerCache) get() (dock, popup Rect) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.dirty {
		return c.dock, c.popup
	}
	data, err := hyprRequest("j/layers")
	if err != nil {
		return c.dock, c.popup
	}
	var raw map[string]struct {
		Levels map[string][]struct {
			X, Y, W, H int
			Namespace  string `json:"namespace"`
		} `json:"levels"`
	}
	if json.Unmarshal(data, &raw) != nil {
		return c.dock, c.popup
	}
	c.dock, c.popup = Rect{}, Rect{}
	for _, monitor := range raw {
		for _, level := range monitor.Levels {
			for _, l := range level {
				switch l.Namespace {
				case "hypr-dock":
					c.dock = Rect{l.X, l.Y, l.W, l.H, true}
				case "dock-popup":
					c.popup = Rect{l.X, l.Y, l.W, l.H, true}
				}
			}
		}
	}
	c.dirty = false
	return c.dock, c.popup
}

// ──────────────── Controle do hypr-dock ────────────────

func startDock() {
	// Mata qualquer instância anterior (idempotência) e inicia uma nova.
	exec.Command("pkill", "-x", "hypr-dock").Run()
	cmd := exec.Command("hypr-dock")
	if err := cmd.Start(); err != nil {
		log.Println("erro ao iniciar hypr-dock:", err)
	}
	// NÃO fazemos Wait; o handler de SIGCHLD recolhe o zumbi.
}

func stopDock() {
	exec.Command("pkill", "-x", "hypr-dock").Run()
}

// ──────────────── Eventos do Hyprland ────────────────

var (
	popupOpen         atomic.Bool
	dockLayerOpen     atomic.Bool
	activeWorkspaceID atomic.Int32
)

func listenEvents(layers *LayerCache, reloadCh, monitorCh chan struct{}) {
	for {
		conn, err := net.Dial("unix", socketPath(".socket2.sock"))
		if err != nil {
			time.Sleep(time.Second)
			continue
		}
		scanner := bufio.NewScanner(conn)
		scanner.Buffer(make([]byte, 1024*1024), 1024*1024)
		for scanner.Scan() {
			parts := strings.SplitN(scanner.Text(), ">>", 2)
			if len(parts) != 2 {
				continue
			}
			event, data := parts[0], parts[1]
			switch event {
			case "openlayer":
				layers.markDirty()
				if data == "dock-popup" {
					popupOpen.Store(true)
				} else if data == "hypr-dock" {
					dockLayerOpen.Store(true)
				}
			case "closelayer":
				layers.markDirty()
				if data == "dock-popup" {
					popupOpen.Store(false)
				} else if data == "hypr-dock" {
					dockLayerOpen.Store(false)
				}
			case "workspace":
				var id int32
				fmt.Sscanf(data, "%d", &id)
				activeWorkspaceID.Store(id)
			case "focusedmon":
				select {
				case monitorCh <- struct{}{}:
				default:
				}
			case "monitoradded", "monitorremoved":
				select {
				case reloadCh <- struct{}{}:
				default:
				}
			}
		}
		conn.Close()
		time.Sleep(500 * time.Millisecond)
	}
}

// ──────────────── Helpers de janela ────────────────

func windowTouchesDock(clients []Client, wsID int, mon Monitor, dock Rect, edge string) bool {
	if !dock.Found {
		// fallback antes da camada estar mapeada
		switch edge {
		case "bottom":
			dock = Rect{mon.X, mon.Y + mon.Height - 120, mon.Width, 120, true}
		case "top":
			dock = Rect{mon.X, mon.Y, mon.Width, 120, true}
		case "left":
			dock = Rect{mon.X, mon.Y, 120, mon.Height, true}
		case "right":
			dock = Rect{mon.X + mon.Width - 120, mon.Y, 120, mon.Height, true}
		}
	}
	for _, c := range clients {
		if !c.Mapped || c.Hidden || c.Workspace.ID != wsID {
			continue
		}
		if c.At[0] < dock.X+dock.W && c.At[0]+c.Size[0] > dock.X &&
			c.At[1] < dock.Y+dock.H && c.At[1]+c.Size[1] > dock.Y {
			return true
		}
	}
	return false
}

// ──────────────── CLI / PID ────────────────

func stopRunning() {
	data, err := os.ReadFile(pidFile)
	if err != nil {
		fmt.Println("! Daemon não está rodando")
		return
	}
	var pid int
	fmt.Sscanf(strings.TrimSpace(string(data)), "%d", &pid)
	proc, err := os.FindProcess(pid)
	if err != nil {
		fmt.Println("! Daemon não está rodando")
		os.Remove(pidFile)
		return
	}
	if proc.Signal(syscall.Signal(0)) != nil {
		fmt.Println("! Daemon não está rodando")
		os.Remove(pidFile)
		return
	}
	proc.Signal(syscall.SIGTERM)
	time.Sleep(500 * time.Millisecond)
	// força se ainda estiver vivo
	if proc.Signal(syscall.Signal(0)) == nil {
		proc.Signal(syscall.SIGKILL)
		time.Sleep(200 * time.Millisecond)
	}
	stopDock()
	fmt.Println("✓ Daemon parado")
}

func reloadRunning() {
	data, err := os.ReadFile(pidFile)
	if err != nil {
		fmt.Println("! Daemon não está rodando")
		return
	}
	var pid int
	fmt.Sscanf(strings.TrimSpace(string(data)), "%d", &pid)
	proc, err := os.FindProcess(pid)
	if err != nil || proc.Signal(syscall.Signal(0)) != nil {
		fmt.Println("! Daemon não está rodando")
		os.Remove(pidFile)
		return
	}
	proc.Signal(syscall.SIGUSR1)
	fmt.Println("→ Sinal de reload enviado")
}

func printHelp() {
	fmt.Println(`hypr-dock-autohide — daemon de autohide/dodge para o hypr-dock

Uso:
  hypr-dock-autohide [flag]

Flags:
  -s, --stop     Para o daemon e fecha o dock
  -r, --reload   Reinicia o daemon (relê o config)
  -h, --help     Exibe esta mensagem`)
}

// ──────────────── Main ────────────────

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "-s", "--stop":
			stopRunning()
			return
		case "-r", "--reload":
			reloadRunning()
			return
		case "-h", "--help":
			printHelp()
			return
		default:
			fmt.Printf("Flag desconhecida: %s\n\n", os.Args[1])
			printHelp()
			os.Exit(1)
		}
	}

	// ═══ Início do daemon ═══

	// Handler de SIGCHLD: recolhe imediatamente qualquer processo filho morto,
	// evitando zumbis.
	sigchld := make(chan os.Signal, 1)
	signal.Notify(sigchld, syscall.SIGCHLD)
	go func() {
		for range sigchld {
			for {
				var ws syscall.WaitStatus
				pid, err := syscall.Wait4(-1, &ws, syscall.WNOHANG, nil)
				if err != nil || pid <= 0 {
					break
				}
			}
		}
	}()

	home, _ := os.UserHomeDir()
	configPath := filepath.Join(home, ".config/scripts/hypr-dock/autohide.json")
	cfg := loadConfig(configPath)

	// grava PID
	os.WriteFile(pidFile, []byte(fmt.Sprintf("%d\n", os.Getpid())), 0644)
	defer os.Remove(pidFile)

	// tratamento de SIGTERM/SIGINT (parada limpa)
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		<-sigs
		stopDock()
		os.Remove(pidFile)
		os.Exit(0)
	}()

	// SIGUSR1 -> reload completo (reinicia o próprio binário)
	usr1 := make(chan os.Signal, 1)
	signal.Notify(usr1, syscall.SIGUSR1)
	go func() {
		<-usr1
		fmt.Println("→ Recarregando...")
		stopDock()
		os.Remove(pidFile)
		exec.Command(os.Args[0]).Start()
		os.Exit(0)
	}()

	layers := &LayerCache{dirty: true}
	reloadCh := make(chan struct{}, 1)
	monitorCh := make(chan struct{}, 1)
	go listenEvents(layers, reloadCh, monitorCh)

	// monitor inicial
	focusedMon, err := getFocusedMonitor()
	if err != nil {
		log.Fatalf("erro ao obter monitor: %v", err)
	}
	activeWorkspaceID.Store(getActiveWorkspaceID())

	dockVisible := false
	hideTimer := 0
	dockRestartCooldown := 0
	centerLo, centerHi := centerBand(focusedMon, cfg.ActivationWidth)

	// inicia dock no modo dodge
	if cfg.Dodge == 1 {
		startDock()
		dockVisible = true
	}

	var configMtime int64
	if info, err := os.Stat(configPath); err == nil {
		configMtime = info.ModTime().UnixNano()
	}

	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	fmt.Printf("→ hypr-dock-autohide iniciado (PID %d) [modo: %s]\n",
		os.Getpid(), map[int]string{0: "autohide", 1: "dodge"}[cfg.Dodge])

	for {
		select {
		case <-reloadCh:
			if m, err := getFocusedMonitor(); err == nil {
				focusedMon = m
				centerLo, centerHi = centerBand(focusedMon, cfg.ActivationWidth)
			}

		case <-monitorCh:
			if dockVisible {
				stopDock()
				dockVisible = false
				hideTimer = 0
			}
			if m, err := getFocusedMonitor(); err == nil {
				focusedMon = m
				centerLo, centerHi = centerBand(focusedMon, cfg.ActivationWidth)
				activeWorkspaceID.Store(getActiveWorkspaceID())
			}

		case <-ticker.C:
			// recarga de config
			if info, err := os.Stat(configPath); err == nil && info.ModTime().UnixNano() != configMtime {
				configMtime = info.ModTime().UnixNano()
				newCfg := loadConfig(configPath)
				oldDodge := cfg.Dodge
				cfg = newCfg
				centerLo, centerHi = centerBand(focusedMon, cfg.ActivationWidth)

				if oldDodge != cfg.Dodge {
					if cfg.Dodge == 1 && !dockVisible {
						startDock()
						dockVisible = true
					} else if cfg.Dodge == 0 && dockVisible {
						stopDock()
						dockVisible = false
					}
				}
				fmt.Println("→ Configuração recarregada")
			}

			if dockRestartCooldown > 0 {
				dockRestartCooldown--
				continue
			}

			pos, err := getCursorPos()
			if err != nil {
				continue
			}

			clients, err := getClients()
			if err != nil {
				continue
			}

			dock, popup := layers.get()
			isPopupOpen := popupOpen.Load()
			wsID := int(activeWorkspaceID.Load())
			isFullscreen := anyFullscreen(clients, wsID)

			// sincroniza estado visível com a camada real
			if dockVisible && !dockLayerOpen.Load() {
				dockVisible = false
				hideTimer = 0
			}

			cursorOnDockMon := cursorOnMonitor(pos, focusedMon)

			// ── DODGE MODE ────────────────────────────────────────────
			if cfg.Dodge == 1 {
				if isFullscreen || !cursorOnDockMon {
					if dockVisible {
						stopDock()
						dockVisible = false
					}
					hideTimer = 0
					continue
				}

				mouseOnDock := dockVisible && dock.Contains(pos)
				mouseOnPopup := isPopupOpen && popup.Contains(pos)
				mouseInActivation := cursorOnDockMon &&
					inEdgeZone(pos, cfg.Edge, cfg.ActivateZone, focusedMon) &&
					inEdgeCenter(pos, cfg.Edge, centerLo, centerHi)

				if mouseInActivation || mouseOnDock || mouseOnPopup {
					if !dockVisible {
						startDock()
						dockVisible = true
						dockRestartCooldown = 5
					}
					hideTimer = 0
				} else {
					if windowTouchesDock(clients, wsID, focusedMon, dock, cfg.Edge) {
						hideTimer++
						if hideTimer >= cfg.HideDelay && dockVisible {
							stopDock()
							dockVisible = false
						}
					} else {
						hideTimer = 0
						if !dockVisible {
							startDock()
							dockVisible = true
							dockRestartCooldown = 5
						}
					}
				}
				continue
			}

			// ── AUTOHIDE MODE ─────────────────────────────────────────
			if isPopupOpen && popup.Contains(pos) {
				if !dockVisible {
					startDock()
					dockVisible = true
				}
				hideTimer = 0
				continue
			}

			// zona vertical segura
			var zoneDepth int
			switch {
			case !dockVisible:
				zoneDepth = cfg.ActivateZone
			case isPopupOpen && popup.Found && dock.Found:
				zoneDepth = popupDepth(cfg.Edge, popup, focusedMon)
			case dock.Found:
				zoneDepth = dock.H
			default:
				zoneDepth = 120
			}

			// zona horizontal segura
			var zoneXLo, zoneXHi int
			switch {
			case !dockVisible:
				zoneXLo, zoneXHi = centerLo, centerHi
			case isPopupOpen && popup.Found:
				zoneXLo, zoneXHi = popup.X, popup.X+popup.W
			case dock.Found:
				zoneXLo, zoneXHi = dock.X, dock.X+dock.W
			default:
				zoneXLo, zoneXHi = focusedMon.X, focusedMon.X+focusedMon.Width
			}

			inSafeZone := cursorOnDockMon &&
				inEdgeZone(pos, cfg.Edge, zoneDepth, focusedMon) &&
				inEdgeCenter(pos, cfg.Edge, zoneXLo, zoneXHi)

			if inSafeZone {
				hideTimer = 0
				if !dockVisible && !isFullscreen {
					startDock()
					dockVisible = true
				}
			} else if dockVisible {
				hideTimer++
				if hideTimer >= cfg.HideDelay {
					stopDock()
					dockVisible = false
					hideTimer = 0
				}
			}
		}
	}
}
