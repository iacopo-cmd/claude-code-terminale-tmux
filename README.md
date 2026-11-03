# claude-code-terminale-tmux

🇮🇹 **Italiano** · 🇬🇧 [English](README.en.md)

Script di shell per **Claude Code nel terminale**: un progetto per sessione **tmux**, sessioni che **non si perdono
se cade l'SSH**, e un **indice dei lavori** per crearli e riaprirli con un comando.

```
$ lavori
LAVORO     STATO    CARTELLA                     ULTIMO USO        DESCRIZIONE
server     ● aperto /root                        2026-11-03 09:12  Server: manutenzione
sito       chiuso   /srv/sito                    2026-11-02 18:40  Sito della ditta

$ lavori sito          # ti riattacca, o riapre la sessione con l'ultima conversazione di Claude
```

---

## ⚠️ Prima di tutto: NON è per tutti

Questo strumento è **comodissimo**, ma è anche **pericoloso**. È pensato per chi **amministra un server** e sa cosa
vuol dire lasciare aperta una sessione con Claude Code, di solito come **root**. Se non sai cosa sono tmux, i
permessi di root e i rischi di una sessione lasciata aperta, **non usarlo**.

**I rischi, chiari:**

1. **Le sessioni restano aperte apposta.** Claude Code continua a girare dentro tmux anche quando ti scolleghi.
   Chi riesce a entrare sulla macchina con lo stesso utente (o come root), o arriva al socket di tmux, **si
   riattacca e trova Claude pronto**, con tutti i permessi di quella sessione.
2. **Fa riemergere quello che stavi facendo.** La cronologia della finestra tmux conserva comandi, risposte e
   output, **compresi segreti** incollati o stampati per sbaglio (password, chiavi, token). Chi si riattacca li vede.
3. **Riaprire un lavoro riprende la conversazione intera.** `lavori <nome>` riapre l'ultima conversazione di Claude
   in quella cartella, con tutto il suo contenuto e il suo contesto.
4. **Separa il contesto, NON i permessi.** Ogni lavoro ha la sua cronologia e la sua memoria, ma se giri come root
   un lavoro può comunque leggere e modificare le cartelle degli altri. La separazione la rispettano le istruzioni
   (`CLAUDE.md`) e chi lavora, non un blocco tecnico.
5. **L'indice dice dove guardare.** Le conversazioni restano salvate in `~/.claude/projects/` (lo fa Claude Code di
   suo); l'indice elenca cartelle e descrizioni dei lavori, quindi è un'informazione da proteggere (è `600`, root).

**Buone pratiche:** accesso SSH solo con chiave, firewall sull'SSH, niente utenti condivisi, chiudi le sessioni che
non usi (`exit` in Claude, poi Invio), non incollare segreti nel terminale, e ricorda che `tmux ls` mostra tutto
quello che è aperto.

---

## Come funziona

- **La cartella divide i progetti.** Claude Code tiene conversazioni e memoria **per cartella di lavoro**
  (`~/.claude/projects/<cartella>/`) e all'avvio legge il `CLAUDE.md` della cartella. Cartelle diverse = contesti
  diversi: in un lavoro Claude non vede la cronologia degli altri.
- **tmux tiene in vita la sessione.** Se cade la connessione, Claude continua a girare e tu ti riattacchi. Ogni
  lavoro ha la sua sessione tmux, così puoi averne più di uno aperto e passare dall'uno all'altro.
- **`lavori` mette insieme le due cose** e tiene un indice di cosa esiste, dove sta e quando l'hai usato.

## Comandi

| Comando | Cosa fa |
|---|---|
| `lavori` | elenco: stato (● aperto, chiuso, ✗ cartella mancante), cartella, ultimo uso, descrizione |
| `lavori <nome>` | apre il lavoro: si riattacca alla sua sessione tmux, oppure la crea nella cartella giusta e avvia Claude riprendendo **l'ultima conversazione** (`--continue`) |
| `lavori <nome> <id>` | come sopra, ma riprende quella conversazione (`--resume <id>`) |
| `lavori nuovo <nome> <cartella> "descrizione"` | crea il lavoro: la cartella e un `CLAUDE.md` di partenza (se mancano) e la riga nell'indice |
| `lavori info <nome>` | dettagli: cartella, `CLAUDE.md`, memoria, ultime conversazioni con id, data e dimensione |
| `lavori descrivi <nome> "descrizione"` | cambia la descrizione |
| `lavori togli <nome>` | toglie dall'indice (chiede conferma); **non cancella** cartella né conversazioni |
| `lavori aiuto` | la guida |

Dentro tmux: **Ctrl-b d** ti stacchi senza chiudere niente, **Ctrl-b s** passi a un altro lavoro.
Se lanci `lavori <altro>` mentre sei già in tmux, passa all'altra sessione invece di annidarla.

**Controlli:** nomi solo minuscole, numeri, `-` e `_`; niente nomi doppi; **una cartella non può appartenere a due
lavori** (sarebbe lo stesso contesto di Claude); niente cartelle di sistema (`/`, `/etc`, `/usr`…); id di
conversazione verificato; avviso se esiste già una sessione tmux con quel nome fuori dall'indice.

## File

| Cosa | Dove |
|---|---|
| comando | `/usr/local/bin/lavori` |
| indice | `/etc/lavori/indice.tsv` (nome, sessione tmux, cartella, creato, ultimo uso, descrizione); a ogni modifica copia in `indice.tsv.prima`, scrittura su file temporaneo, blocco con `flock` |
| registro | `/var/log/lavori.log` (aperture, creazioni, rimozioni) |
| riga di stato | `~/.claude/avviso-tmux.sh` (facoltativo, vedi sotto) |

Si possono cambiare con le variabili `LAVORI_DIR`, `LAVORI_REGISTRO`, `CLAUDE_BIN`, `PROGETTI_CLAUDE`.

## Installazione

Serve: Linux, `bash`, `tmux`, `flock` (util-linux), Claude Code già installato. Va lanciato come **root**.

```bash
git clone https://github.com/iacopo-cmd/claude-code-terminale-tmux.git
cd claude-code-terminale-tmux
sudo ./installa.sh
lavori nuovo server /root "Server: manutenzione"
lavori server
```

### Riga di stato e avvisi (facoltativo)

`avviso-tmux.sh` mostra in basso nella riga di stato di Claude Code in che sessione sei e cosa rilanciare
(`● tmux "server": se cade la linea rilancia lavori server`). Se Claude **non** gira dentro tmux mostra invece un
avviso rosso, e qualche promemoria in chat. `installa.sh` lo copia in `~/.claude/`; per attivarlo **aggiungi a mano**
il contenuto di `impostazioni-esempio.json` al tuo `~/.claude/settings.json`, senza sovrascrivere le impostazioni
che hai già.

## Licenza

MIT. Nessuna garanzia: lo usi a tuo rischio (vedi le avvertenze qui sopra).
