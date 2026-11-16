#!/usr/bin/env bash
# Patches Nebula's color prefs in Zen's prefs.js using matugen's output.
# Zen must be closed for the change to stick (it flushes prefs.js on exit).

snippet="$HOME/.cache/matugen/nebula-colors.js"
prefs="$HOME"/.config/zen/*/prefs.js

was_running=false
pgrep -x zen-bin > /dev/null && was_running=true
if $was_running; then
  pkill zen-bin
  while pgrep -x zen-browser > /dev/null; do sleep 0.5; done
fi

while IFS= read -r line; do
  key=$(sed -n 's/user_pref("\([^"]*\)".*/\1/p' <<< "$line")
  [[ -z "$key" ]] && continue
  sed -i "s|user_pref(\"$key\".*|$line|" $prefs
done < "$snippet"

$was_running && zen-browser &
