#!/bin/bash
# Installa "lavori" e (facoltativo) la riga di stato per Claude Code. Leggere le avvertenze nel README.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Va lanciato come root (sudo ./installa.sh)"; exit 1; }
for c in tmux flock awk; do command -v "$c" >/dev/null || { echo "Manca: $c"; exit 1; }; done
QUI="$(cd "$(dirname "$0")" && pwd)"

if [ -e /usr/local/bin/lavori ] && ! cmp -s "$QUI/lavori" /usr/local/bin/lavori; then
    cp -p /usr/local/bin/lavori "/usr/local/bin/lavori.prima-$(date +%Y%m%d%H%M%S)"
    echo "Copia della versione precedente: /usr/local/bin/lavori.prima-*"
fi
install -m 755 "$QUI/lavori" /usr/local/bin/lavori
mkdir -p /etc/lavori && chmod 700 /etc/lavori
echo "Installato /usr/local/bin/lavori (indice in /etc/lavori/indice.tsv)."

mkdir -p "$HOME/.claude"
if [ -e "$HOME/.claude/avviso-tmux.sh" ] && ! cmp -s "$QUI/avviso-tmux.sh" "$HOME/.claude/avviso-tmux.sh"; then
    cp -p "$HOME/.claude/avviso-tmux.sh" "$HOME/.claude/avviso-tmux.sh.prima-$(date +%Y%m%d%H%M%S)"
fi
install -m 755 "$QUI/avviso-tmux.sh" "$HOME/.claude/avviso-tmux.sh"
echo "Copiato $HOME/.claude/avviso-tmux.sh."
echo
echo "Per la riga di stato e gli avvisi: aggiungi A MANO il contenuto di impostazioni-esempio.json"
echo "a $HOME/.claude/settings.json (non viene modificato da questo script)."
echo
echo "Primo lavoro:  lavori nuovo <nome> <cartella> \"descrizione\"   poi   lavori <nome>"
