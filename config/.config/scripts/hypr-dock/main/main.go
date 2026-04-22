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

const pollInterval = 50 * time.Millisecond

// ─── Config ───────────────────────────────────────────────────────────────────

type Config struct {
	Edge            string `json:"edge"`
	ActivateZone    int    `json:"activate_zone"`
	HideDelay       int    `json:"hide_delay"`
	ActivationWidth int    `json:"activation_width"`
	Dodge           int    `json:"dodge"`
}

func defaultConfig() Config {
	return Config{Edge: "bottom", ActivateZone: 5, HideDelay: 10, ActivationWidth: 400}
}

func loadConfig(path string) Config {
	cfg := defaultConfig()
	if f, err := os.Open(path); err == nil {
		json.NewDecoder(f).Decode(&cfg)
		f.Close()
	}
	return cfg
}

// ─── Types ────────────────────────────────────────────────────────────────────

type Pos struct {
	X int `json:"x"`
	Y int `json:"y"`
}

type Rect struct {
	X, Y, W, H int
	Found      bool
}

func (r Rect) Contains(p Pos) bool {
	return r.Found && p.X >= r.X && p.X <= r.X+r.W && p.Y >= r.Y && p.Y <= r.Y+r.H
}

type Client struct {
	At        [2]int `json:"at"`
	Size      [2]int `json:"size"`
	Workspace struct {
		ID int `json:"id"`
	} `json:"workspace"`
	Hidden bool `json:"hidden"`
	Mapped bool `json:"mapped"`
}

type Monitor struct {
	X       int  `json:"x"`
	Y       int  `json:"y"`
	Width   int  `json:"width"`
	Height  int  `json:"height"`
	Focused bool `json:"focused"`
}

// ─── Edge helpers ─────────────────────────────────────────────────────────────

// inEdgeZone reports whether pos is within `zone` pixels of the monitor's edge.
// Uses monitor-relative coordinates to support multi-monitor setups.
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

// inEdgeCenter reports whether pos is within the central activation band.
// lo and hi are absolute screen coordinates.
func inEdgeCenter(p Pos, edge string, lo, hi int) bool {
	switch edge {
	case "bottom", "top":
		return p.X >= lo && p.X <= hi
	case "left", "right":
		return p.Y >= lo && p.Y <= hi
	}
	return false
}

// popupZoneDepth returns how deep from the edge the popup extends,
// using monitor-relative coordinates.
func popupZoneDepth(edge string, popup Rect, mon Monitor) int {
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

// calcCenter returns the absolute lo/hi coordinates of the central activation
// band, accounting for the monitor's X offset.
func calcCenter(mon Monitor, activationWidth int) (lo, hi int) {
	lo = mon.X + (mon.Width-activationWidth)/2
	hi = lo + activationWidth
	return
}

// ─── IPC ──────────────────────────────────────────────────────────────────────

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
	return p, json.Unmarshal(data, &p)
}

func getMonitors() ([]Monitor, error) {
	data, err := hyprRequest("j/monitors")
	if err != nil {
		return nil, err
	}
	var monitors []Monitor
	return monitors, json.Unmarshal(data, &monitors)
}

func getFocusedMonitor() (Monitor, error) {
	monitors, err := getMonitors()
	if err != nil {
		return Monitor{}, err
	}
	for _, m := range monitors {
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
	return clients, json.Unmarshal(data, &clients)
}

// cursorOnMonitor returns true if pos is within the monitor's bounds.
func cursorOnMonitor(p Pos, mon Monitor) bool {
	return p.X >= mon.X && p.X < mon.X+mon.Width &&
		p.Y >= mon.Y && p.Y < mon.Y+mon.Height
}

// ─── Layer cache ──────────────────────────────────────────────────────────────

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
			X         int    `json:"x"`
			Y         int    `json:"y"`
			W         int    `json:"w"`
			H         int    `json:"h"`
			Namespace string `json:"namespace"`
		} `json:"levels"`
	}
	if json.Unmarshal(data, &raw) != nil {
		return c.dock, c.popup
	}
	c.dock, c.popup = Rect{}, Rect{}
	for _, mon := range raw {
		for _, entries := range mon.Levels {
			for _, e := range entries {
				switch e.Namespace {
				case "hypr-dock":
					c.dock = Rect{e.X, e.Y, e.W, e.H, true}
				case "dock-popup":
					c.popup = Rect{e.X, e.Y, e.W, e.H, true}
				}
			}
		}
	}
	c.dirty = false
	return c.dock, c.popup
}

// ─── Dock helpers ─────────────────────────────────────────────────────────────

func startDock() { exec.Command("hypr-dock").Start() }
func stopDock()  { exec.Command("pkill", "-x", "hypr-dock").Run() }

func windowTouchesDock(clients []Client, wsID int, mon Monitor, dock Rect, edge string) bool {
	// Fallback bounds when dock layer isn't mapped yet
	if !dock.Found {
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

// ─── Global state (updated by Hyprland events) ────────────────────────────────

var (
	popupOpen         atomic.Bool
	dockLayerOpen     atomic.Bool
	fullscreenActive  atomic.Bool
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
			case "fullscreen":
				fullscreenActive.Store(data == "1")
			case "openlayer":
				layers.markDirty()
				switch data {
				case "dock-popup":
					popupOpen.Store(true)
				case "hypr-dock":
					dockLayerOpen.Store(true)
				}
			case "closelayer":
				layers.markDirty()
				switch data {
				case "dock-popup":
					popupOpen.Store(false)
				case "hypr-dock":
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

// ─── PID / stop ───────────────────────────────────────────────────────────────

const pidFile = "/tmp/hypr-dock-autohide.pid"

func waitForExit(proc *os.Process, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if proc.Signal(syscall.Signal(0)) != nil {
			return true
		}
		time.Sleep(50 * time.Millisecond)
	}
	return false
}

func stopRunning() {
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
	proc.Signal(syscall.SIGTERM)
	if !waitForExit(proc, 2*time.Second) {
		fmt.Println("⚠ Daemon não respondeu, forçando...")
		proc.Signal(syscall.SIGKILL)
		waitForExit(proc, time.Second)
	}
	stopDock()
	fmt.Println("✓ Daemon parado")
}

// ─── CLI ──────────────────────────────────────────────────────────────────────

func printHelp() {
	fmt.Println(`hypr-dock-autohide — daemon de autohide/dodge para o hypr-dock

Uso:
  hypr-dock-autohide [flag]

Flags:
  -s, --stop     Para o daemon e fecha o dock
  -r, --reload   Reinicia o daemon (relê o config)
  -h, --help     Exibe esta mensagem`)
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

// ─── Main ─────────────────────────────────────────────────────────────────────

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

	home, _ := os.UserHomeDir()
	configPath := filepath.Join(home, ".config/scripts/hypr-dock/autohide.json")
	cfg := loadConfig(configPath)

	os.WriteFile(pidFile, []byte(fmt.Sprintf("%d\n", os.Getpid())), 0644)
	defer os.Remove(pidFile)

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGTERM, syscall.SIGINT)
	go func() { <-sigs; stopDock(); os.Remove(pidFile); os.Exit(0) }()

	// SIGUSR1 triggers a clean restart (used by --reload)
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

	var configMtime int64
	if info, _ := os.Stat(configPath); info != nil {
		configMtime = info.ModTime().UnixNano()
	}

	focusedMon, err := getFocusedMonitor()
	if err != nil {
		log.Fatalf("erro ao obter monitor: %v", err)
	}

	activeWorkspaceID.Store(getActiveWorkspaceID())

	dockVisible := false
	hideTimer := 0
	dockRestartCooldown := 0
	centerLo, centerHi := calcCenter(focusedMon, cfg.ActivationWidth)

	if cfg.Dodge == 1 {
		startDock()
		dockVisible = true
	}

	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()
	fmt.Printf("→ hypr-dock-autohide iniciado (PID %d) [modo: %s]\n",
		os.Getpid(), map[int]string{0: "autohide", 1: "dodge"}[cfg.Dodge])

	for {
		select {
		case <-reloadCh:
			if mon, err := getFocusedMonitor(); err == nil {
				focusedMon = mon
				centerLo, centerHi = calcCenter(focusedMon, cfg.ActivationWidth)
			}

		case <-monitorCh:
			// Cursor moved to a different monitor — close dock and update bounds
			if dockVisible {
				stopDock()
				dockVisible = false
				hideTimer = 0
			}
			if mon, err := getFocusedMonitor(); err == nil {
				focusedMon = mon
				centerLo, centerHi = calcCenter(focusedMon, cfg.ActivationWidth)
				activeWorkspaceID.Store(getActiveWorkspaceID())
			}

		case <-ticker.C:
			// Reload config if file changed
			if info, err := os.Stat(configPath); err == nil && info.ModTime().UnixNano() != configMtime {
				configMtime = info.ModTime().UnixNano()
				newCfg := loadConfig(configPath)
				prevDodge := cfg.Dodge
				cfg = newCfg
				centerLo, centerHi = calcCenter(focusedMon, cfg.ActivationWidth)
				if prevDodge != cfg.Dodge {
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

			dock, popup := layers.get()
			isPopupOpen := popupOpen.Load()
			isFullscreen := fullscreenActive.Load()

			// Sync visible state with actual layer state
			if dockVisible && !dockLayerOpen.Load() {
				dockVisible = false
				hideTimer = 0
			}

			// Cursor must be on the focused monitor to interact with the dock
			cursorOnDockMonitor := cursorOnMonitor(pos, focusedMon)

			mouseInActivation := cursorOnDockMonitor &&
				inEdgeZone(pos, cfg.Edge, cfg.ActivateZone, focusedMon) &&
				inEdgeCenter(pos, cfg.Edge, centerLo, centerHi)

			// ── DODGE MODE ────────────────────────────────────────────────
			if cfg.Dodge == 1 {
				// Hide dock on fullscreen or cursor on another monitor
				if isFullscreen || !cursorOnDockMonitor {
					if dockVisible {
						stopDock()
						dockVisible = false
					}
					hideTimer = 0
					continue
				}

				mouseOnDock := dockVisible && dock.Contains(pos)
				mouseOnPopup := isPopupOpen && popup.Contains(pos)

				if mouseInActivation || mouseOnDock || mouseOnPopup {
					if !dockVisible {
						startDock()
						dockVisible = true
						dockRestartCooldown = 5
					}
					hideTimer = 0
				} else {
					clients, _ := getClients()
					wsID := int(activeWorkspaceID.Load())
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

			// ── AUTOHIDE MODE ─────────────────────────────────────────────

			// If cursor is on another monitor, let the hide timer run normally
			// (dock will close after HideDelay cycles without resetting the timer)

			// Keep dock visible while mouse is over the preview popup
			if isPopupOpen && popup.Contains(pos) {
				if !dockVisible {
					startDock()
					dockVisible = true
				}
				hideTimer = 0
				continue
			}

			// Vertical safe zone: expands to cover the popup when open
			var zoneDepth int
			switch {
			case !dockVisible:
				zoneDepth = cfg.ActivateZone
			case isPopupOpen && popup.Found && dock.Found:
				zoneDepth = popupZoneDepth(cfg.Edge, popup, focusedMon)
			case dock.Found:
				zoneDepth = dock.H
			default:
				zoneDepth = 120
			}

			// Horizontal safe zone: follows dock or popup bounds when visible
			var centerZoneLo, centerZoneHi int
			switch {
			case !dockVisible:
				centerZoneLo, centerZoneHi = centerLo, centerHi
			case isPopupOpen && popup.Found:
				centerZoneLo, centerZoneHi = popup.X, popup.X+popup.W
			case dock.Found:
				centerZoneLo, centerZoneHi = dock.X, dock.X+dock.W
			default:
				centerZoneLo, centerZoneHi = focusedMon.X, focusedMon.X+focusedMon.Width
			}

			inSafeZone := cursorOnDockMonitor &&
				inEdgeZone(pos, cfg.Edge, zoneDepth, focusedMon) &&
				inEdgeCenter(pos, cfg.Edge, centerZoneLo, centerZoneHi)

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
