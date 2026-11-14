#!/bin/bash
# Installa "lavori" e (facoltativo) la riga di stato per Claude Code. Leggere le avvertenze nel README.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Va lanciato come root (sudo ./installa.sh)"; exit 1; }
for c in tmux flock awk; do command -v "$c" >/dev/null || { echo "Manca: $c"; exit 1; }; done
QUI="$(cd "$(dirname "$0")" && pwd)"

# metti <file>: installa in /usr/local/bin; se la versione installata e' diversa, prima ne fa una copia .prima-DATA
metti() {
    local f=$1 dest=/usr/local/bin/$1
    if [ -e "$dest" ] && ! cmp -s "$QUI/$f" "$dest"; then
        cp -p "$dest" "$dest.prima-$(date +%Y%m%d%H%M%S)"; echo "Copia della versione precedente: $dest.prima-*"
    fi
    install -m 755 "$QUI/$f" "$dest"
}
for f in lavori lavori-ore lavori-barra lavori-risposte iacopo iacopo2; do metti "$f"; done
# La guardia spesso si adatta alla macchina (avvisi col formato del server, nome macchina...): se quella installata
# e' diversa dal repo NON la tocco, cosi' un aggiornamento non la rompe. Per sostituirla: LAVORI_GUARDIA_FORZA=1
if [ -e /usr/local/bin/lavori-guardia ] && ! cmp -s "$QUI/lavori-guardia" /usr/local/bin/lavori-guardia \
   && [ "${LAVORI_GUARDIA_FORZA:-0}" != 1 ]; then
    echo "Guardia: lascio quella installata (e' diversa dal repo, adattata a questa macchina). Per sostituirla: LAVORI_GUARDIA_FORZA=1 ./installa.sh"
else
    metti lavori-guardia
fi
command -v python3 >/dev/null || echo "Nota: manca python3, il pannello degli scambi (lavori-risposte) non partira'."
mkdir -p /etc/lavori && chmod 700 /etc/lavori
echo "Installato /usr/local/bin/lavori, lavori-ore, lavori-barra, lavori-risposte, iacopo, iacopo2, lavori-guardia (indice in /etc/lavori/indice.tsv)."

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
