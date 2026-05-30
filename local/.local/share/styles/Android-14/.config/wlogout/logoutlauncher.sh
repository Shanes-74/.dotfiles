#!/usr/bin/env bash
# wlogout-toggle.sh — Toggle inteligente para wlogout
# Uso: ./wlogout-toggle.sh [opções]
#
# Opções:
#   --columns, -b N     Número de botões por linha (padrão: 4)
#   --top, -T N         Margem superior em px (padrão: 350)
#   --bottom, -B N      Margem inferior em px (padrão: 325)
#   --column-spacing,-c N  Espaçamento entre colunas em px (padrão: 10)
#   --help, -h          Mostra esta ajuda

# ── Configurações padrão ────────────────────────────────────────────────────
COLUMNS=4
MARGIN_TOP=350
MARGIN_BOTTOM=325
COL_SPACING=10
LOCK_FILE="/tmp/wlogout.lock"

# ── Parsing de argumentos ───────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --columns|-b)   COLUMNS="$2";      shift 2 ;;
        --top|-T)       MARGIN_TOP="$2";   shift 2 ;;
        --bottom|-B)    MARGIN_BOTTOM="$2"; shift 2 ;;
        --column-spacing|-c) COL_SPACING="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,12p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
    esac
done

# ── Verificações de dependência ─────────────────────────────────────────────
if ! command -v wlogout &>/dev/null; then
    echo "Erro: wlogout não encontrado no PATH." >&2
    exit 1
fi

# ── Lógica de toggle ─────────────────────────────────────────────────────────
# Tenta matar qualquer instância rodando
if pgrep -x wlogout &>/dev/null; then
    pkill -x wlogout
    rm -f "$LOCK_FILE"
    exit 0
fi

# Garante que não há arquivo de lock órfão
rm -f "$LOCK_FILE"

# ── Lança wlogout ────────────────────────────────────────────────────────────
wlogout \
    -b "$COLUMNS" \
    -T "$MARGIN_TOP" \
    -B "$MARGIN_BOTTOM" \
    -c "$COL_SPACING" &

WLOGOUT_PID=$!

# Aguarda um momento para confirmar que o processo iniciou
sleep 0.3
if kill -0 "$WLOGOUT_PID" 2>/dev/null; then
    echo "$WLOGOUT_PID" > "$LOCK_FILE"
else
    echo "Erro: wlogout falhou ao iniciar." >&2
    exit 1
fi