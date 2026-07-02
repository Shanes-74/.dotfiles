#!/bin/bash

# Executa os comandos iniciais
pywalfox update
systemctl --user restart livepaper

# Verifica se existe uma janela do LibreWolf com título começando por "Menu~"
if hyprctl clients -j | jq -e '.[] | select(.title | test("^Menu~"))' > /dev/null; then
    # Se encontrou, envia F5 para essa janela específica
    hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "F5", window = "title:^(Menu~).*" }))'
else
    # Se não encontrou, envia Ctrl+T (nova aba) e depois F5 para a janela ativa
    # Assumindo que o foco está no LibreWolf ou em algum navegador
    hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "T", window = "activewindow" }))'
fi