#!/bin/bash
# Avvisa se Claude Code NON gira dentro tmux (se cade la linea si perde la sessione).
# Parte di https://github.com/iacopo-cmd/claude-code-terminale-tmux
# Uso: avviso-tmux.sh status  -> riga di stato di Claude (sempre visibile)
#      avviso-tmux.sh start   -> 20 righe in chat all'avvio (hook SessionStart)
#      avviso-tmux.sh minuto  -> 20 righe in chat, max 1 volta al minuto
#                                (hook UserPromptSubmit/PostToolUse/Stop)
cat >/dev/null   # stdin JSON di Claude, non serve
# Comando per rientrare: "lavori <nome>", con il nome preso dall'indice ${LAVORI_DIR:-/etc/lavori}/indice.tsv
# (dentro tmux dalla sessione, fuori dalla cartella).
if [ -n "$TMUX" ]; then
    SESS="$(tmux display-message -p '#S' 2>/dev/null)"
    RIPARTI=lavori
    # il nome del lavoro dalla sessione tmux, nell'indice di "lavori" (${LAVORI_DIR:-/etc/lavori}/indice.tsv)
    LAV="$(awk -F'\t' -v s="$SESS" '!/^#/ && $2 == s { print $1; exit }' "${LAVORI_DIR:-/etc/lavori}/indice.tsv" 2>/dev/null)"
    [ -n "$LAV" ] && RIPARTI="lavori $LAV"
    [ "$1" = status ] && printf '\033[32m● tmux "%s": se cade la linea rilancia %s\033[0m\n' "$SESS" "$RIPARTI"
    exit 0
fi
# fuori da tmux: il lavoro della cartella corrente (il piu' lungo che la contiene), se no l'elenco
LAV="$(awk -F'\t' -v d="$PWD" '!/^#/ && (d == $3 || index(d, $3 "/") == 1) && length($3) > m { m = length($3); n = $1 } END { print n }' "${LAVORI_DIR:-/etc/lavori}/indice.tsv" 2>/dev/null)"
RIPARTI="lavori${LAV:+ $LAV}"
MSG="⚠ NON SEI IN TMUX: se cade la linea perdi la sessione. Esci con /exit e rientra con $RIPARTI"
if [ "$1" = status ]; then
    printf '\033[1;37;41m %s \033[0m\n' "$MSG"
    exit 0
fi
if [ "$1" = minuto ]; then
    # al massimo un avviso ogni 60 s (timestamp in ~/.claude/.ultimo-avviso-tmux)
    T="$HOME/.claude/.ultimo-avviso-tmux"
    ORA=$(date +%s); PRIMA=$(cat "$T" 2>/dev/null || echo 0)
    [ $((ORA - PRIMA)) -lt 60 ] && exit 0
    echo "$ORA" > "$T"
fi
# 20 righe, se no non si vede
RIGHE=""
for i in $(seq 1 20); do RIGHE="$RIGHE\\n$i) $MSG"; done
printf '{"systemMessage": "%s"}\n' "$RIGHE"
