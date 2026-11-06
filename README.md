# claude-code-terminale-tmux

🇮🇹 **Italiano** · 🇬🇧 [English](README.en.md)

Script di shell per **Claude Code nel terminale**: un progetto per sessione **tmux**, sessioni che **non si perdono
se cade l'SSH**, e un **indice dei lavori** per crearli e riaprirli con un comando.

```
$ lavori                       # menu a riquadri, si adatta alla larghezza del terminale
╭──────────────────────────────────────────────────────────────╮
│                     Lavori di Claude Code   (2)                │
├──────────────────────────────────────────────────────────────┤
│  1  ● server                          ultimo uso 2026-11-03 09:12 │
│       Server: manutenzione                                     │
├──────────────────────────────────────────────────────────────┤
│  2  ○ sito                            ultimo uso 2026-11-02 18:40 │
│       Sito della ditta                                         │
╰──────────────────────────────────────────────────────────────╯

$ lavori sito          # ti riattacca, o riapre la sessione con l'ultima conversazione di Claude
```

In basso, la **barra di tmux** mostra sempre cosa sta monitorando: `⏱ tempo della sessione · 🪙 token · ● sessioni aperte`.

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
| `lavori ore [<nome>]` | ore per sessione e totale di un lavoro, o la tabella dei totali di tutti |
| `lavori guida [europea\|inglese\|egiziana\|plancia]` | come stanno i pannelli: `europea` = scrivi a sinistra (default); `inglese` o `egiziana` = scrivi a destra; `plancia` = tre pannelli. Senza argomenti dice quale hai |
| `lavori aiuto` | la guida |

Il menu (`lavori` senza argomenti) e l'elenco sono a **riquadro/griglia**, con descrizione intera a capo e si
adattano alla larghezza del terminale. Nomi e cartelle **senza spazi**.

Dentro tmux: **Ctrl-b d** ti stacchi senza chiudere niente, **Ctrl-b s** passi a un altro lavoro.
Se lanci `lavori <altro>` mentre sei già in tmux, passa all'altra sessione invece di annidarla.

**Controlli:** nomi solo minuscole, numeri, `-` e `_`; niente nomi doppi; **una cartella non può appartenere a due
lavori** (sarebbe lo stesso contesto di Claude); niente cartelle di sistema (`/`, `/etc`, `/usr`…); id di
conversazione verificato; avviso se esiste già una sessione tmux con quel nome fuori dall'indice.

## File

| Cosa | Dove |
|---|---|
| comando | `/usr/local/bin/lavori` |
| conta-ore | `/usr/local/bin/lavori-ore` (inizio/fine di ogni sessione, totali); dati in `/etc/lavori/ore/<nome>.tsv` |
| barra tmux | `/usr/local/bin/lavori-barra` (contenuto della barra: ⏱ tempo · 🪙 token · ● sessioni aperte) |
| pannello scambi | `/usr/local/bin/lavori-risposte` (gli scambi tu ↔ Claude in un pannello a parte; serve `python3`) |
| indice | `/etc/lavori/indice.tsv` (nome, sessione tmux, cartella, creato, ultimo uso, descrizione); a ogni modifica copia in `indice.tsv.prima`, scrittura su file temporaneo, blocco con `flock` |
| registro | `/var/log/lavori.log` (aperture, creazioni, rimozioni) |
| riga di stato (Claude) | `~/.claude/avviso-tmux.sh` (facoltativo, vedi sotto) |

### Pannello degli scambi
Mentre Claude lavora, le sue risposte scorrono via insieme al codice. Aprendo un lavoro su uno schermo largo
(almeno 120 colonne) la sessione si divide in due pannelli:

```
┌─ Claude Code ───────────┬─ scambi tu ↔ Claude ──────────────┐
│ (qui scrivi, qui passano│ ▶ TU 05:44                        │
│  codice, tool, domande) │   si parti con lo script          │
│                         │ ● CLAUDE 05:45                    │
│ > _                     │   Lo script è nel repo e ...      │
└─────────────────────────┴───────────────────────────────────┘
```

A sinistra c'è Claude Code normale, dove scrivi; a destra restano solo le tue battute e le risposte in testo di
Claude (niente tool, niente codice), lette dal vivo dal transcript della conversazione. Per rileggere: `Ctrl-b →`,
poi `Ctrl-b [` e le frecce (`q` per uscire, `Ctrl-b ←` per tornare a scrivere). Quando chiudi Claude il pannello si
chiude da solo.

- `LAVORI_RISPOSTE=0` lo spegne; `LAVORI_RISPOSTE_MIN=<colonne>` cambia la soglia (default 120).
- **La disposizione** si sceglie con `lavori guida`:
  - `lavori guida europea` — scrivi a sinistra, scambi a destra (default, il disegno qui sopra);
  - `lavori guida inglese` oppure `lavori guida egiziana` — scrivi a destra, scambi a sinistra;
  - `lavori guida plancia` — tre pannelli (vedi sotto).

  La scelta resta salvata in `/etc/lavori/guida` e vale dalla prossima apertura. Per una volta sola, nelle guide
  di fianco: `LAVORI_RISPOSTE_LATO=sinistra lavori <nome>` (è il lato degli scambi).

#### La plancia (tre pannelli)

```
┌─ le risposte di Claude ───────────────────────────────────────┐
│ ● CLAUDE 06:02                                                │
│   È in prova: nel pannello in basso a destra ...              │
├─ Claude Code (qui scrivi) ──────┬─ le tue battute + domande ──┤
│                                 │ ? CLAUDE CHIEDE 06:02       │
│ > _                             │   ? Provo così?             │
│                                 │ ▶ TU 06:03                  │
│                                 │   si prova così             │
└─────────────────────────────────┴─────────────────────────────┘
```

Sopra restano le risposte di Claude, a tutta larghezza. Sotto a sinistra c'è Claude Code, dove scrivi e dove
passano codice e tool. Sotto a destra ci sono le tue battute e, in viola, le **domande che Claude ti fa** (le frasi
che finiscono con `?` e le domande a scelta): vedi cosa aspetta risposta e cosa hai risposto. Serve un terminale
di almeno 120 colonne e 26 righe; se è più basso apre di fianco come la guida europea.

A mano, in una sessione già aperta (dal pannello di Claude Code):

```
tmux split-window -vb -d -l 55% 'lavori-risposte --claude'
tmux split-window -h  -d -l 48% 'lavori-risposte --tu'
```
- A mano, in una sessione già aperta: `tmux split-window -h -d -l 60% lavori-risposte`
- Fuori da tmux: `lavori-risposte <nome> --stampa` stampa gli scambi dell'ultima conversazione ed esce
  (con `--tu` solo le tue battute e le domande di Claude, con `--claude` solo le sue risposte).

### Barra di stato tmux (facoltativo)
Per avere in basso ⏱ tempo, 🪙 token e ● sessioni aperte, aggiungi al tuo `~/.tmux.conf`:
```tmux
set -g status on
set -g status-interval 15
set -g status-right-length 90
set -g status-right ' #S  #(/usr/local/bin/lavori-barra #S)'
```

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

## In arrivo (idee, non ancora fatte)

Proprio perché è uno strumento potente (sessioni aperte come root), queste aggiunte servono soprattutto a **non
dimenticarsele aperte**:

- **🪙 conta-token per lavoro**: comando che somma i token dai transcript di ogni progetto (oltre al totale già in barra).
- **Guardia** (cron): controlla le sessioni aperte; se ne resti **staccato** la segnala su un **bot** (es. Telegram) e
  ricorda di chiudere (prime 4 ore ogni ora, poi ogni 4 ore). Quando non c'è niente di aperto, sta zitta.
- **Segnala + conferma**: aprendo un lavoro mentre un altro è ancora aperto, avvisa e chiede conferma.
- **"chiudi tutto" dal bot**: un comando per **chiudere tutte le sessioni da remoto** (dal telefono, via bot) se le
  hai lasciate aperte — la rete di sicurezza di uno strumento che altrimenti ti lascia tutto acceso.

## Licenza

MIT. Nessuna garanzia: lo usi a tuo rischio (vedi le avvertenze qui sopra).
