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
| `lavori 0` | **lavoro zero «Aggiornamenti»**: terminale di root dentro tmux, **senza Claude**, per aggiornamenti e comandi lunghi. Se cade il collegamento il comando continua; rientri con `lavori 0` (uguale: `lavori zero`, `lavori aggiornamenti`; nel menu: `0`). Non sta nell'indice, c'è sempre in cima |
| `lavori opencode` | **OpenCode**: un terminale tmux con [OpenCode](https://opencode.ai) dentro al posto di Claude. Nel menu è l'ultima voce, col numero dopo l'ultimo lavoro. Gira come l'utente che lo apre (entri come `iacopo`: gira come `iacopo`; entri come root: gira come root), nella sua `~/opencode`; compare solo se quell'utente ha OpenCode (`~/.opencode/bin/opencode` o `opencode` nel PATH). Non serve root. `LAVORI_OPENCODE_CARTELLA` e `LAVORI_OPENCODE_CMD` cambiano cartella e comando |
| `lavori stato` | stato degli aggiornamenti (apt): uno in corso, dentro o fuori da tmux; pacchetti rimasti a metà; quanti restano; riavvio in sospeso. Se trova qualcosa di incastrato scrive i comandi per riprendere e, dentro tmux, chiede se mandarlo avanti |
| `lavori nuovo <nome> <cartella> "descrizione"` | crea il lavoro: la cartella e un `CLAUDE.md` di partenza (se mancano) e la riga nell'indice |
| `lavori info <nome>` | dettagli: cartella, `CLAUDE.md`, memoria, ultime conversazioni con id, data e dimensione |
| `lavori descrivi <nome> "descrizione"` | cambia la descrizione |
| `lavori togli <nome>` | toglie dall'indice (chiede conferma); **non cancella** cartella né conversazioni |
| `lavori ore [<nome>]` | ore per sessione e totale di un lavoro, o la tabella dei totali di tutti |
| `lavori guida [europea\|inglese\|egiziana\|plancia]` | come stanno i pannelli: `europea` = scrivi a sinistra (default); `inglese` o `egiziana` = scrivi a destra; `plancia` = tre pannelli. Senza argomenti dice quale hai |
| `lavori iacopo [on\|off]` | **iacopostyle**: accende o spegne i pannelli su tutte le sessioni, aperte e nuove (uguale: `lavori stile`, `lavori styl`, `lavori iacopostyle`). Senza `on`/`off` dice com'è adesso |
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
| barra tmux | `/usr/local/bin/lavori-barra` (la riga della barra: macchina · ⏱ tempo · 🪙 token · ● sessioni aperte · comando della mod · firma; ⚠ se lo schermo è piccolo per i pannelli) |
| comando corto | `/usr/local/bin/iacopo` (`iacopo on` / `iacopo off`: scorciatoia di `lavori iacopo …`) |
| guardia | `/usr/local/bin/lavori-guardia` (sessioni rimaste staccate; stato in `/etc/lavori/guardia/<nome>`) |
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
tmux split-window -vb -d -l 40% 'lavori-risposte --claude'
tmux split-window -h  -d -l 48% 'lavori-risposte --tu'
```
- A mano, in una sessione già aperta: `tmux split-window -h -d -l 60% lavori-risposte`
- Fuori da tmux: `lavori-risposte <nome> --stampa` stampa gli scambi dell'ultima conversazione ed esce
  (con `--tu` solo le tue battute e le domande di Claude, con `--claude` solo le sue risposte).

### Iacopostyle: l'interruttore
I pannelli degli scambi si chiamano **iacopostyle**, e si accendono o spengono con un comando solo, su **tutte le
sessioni aperte** e su quelle che aprirai:

```
lavori iacopo off     # Claude Code da solo: via i pannelli
lavori iacopo on      # rimette i pannelli (secondo "lavori guida")
lavori iacopo         # dice com'è adesso
```

La barra in basso resta sempre, anche da spento, così sai come riaccendere: a sinistra, accanto al nome della
sessione, c'è `✎ per la mod: iacopo off | on · Iacopo, 6 novembre 2026`; a destra lo stato, `iacopostyle on` o `off`.

C'è anche il comando corto, senza `lavori` davanti: `iacopo on`, `iacopo off`, `iacopo`.
Al posto di `lavori iacopo` vanno bene anche `lavori stile`, `lavori styl` e `lavori iacopostyle`. Lo stato resta salvato in
`/etc/lavori/stile`.

### Lavoro zero «Aggiornamenti»: aggiornare senza farsi buttare fuori (Debian e Ubuntu)

`lavori 0` apre un terminale di root dentro tmux, **senza Claude**, fatto apposta per gli aggiornamenti e i comandi
lunghi. Se cade l'SSH l'aggiornamento continua; rientri con `lavori 0` e lo ritrovi dov'era. Vale uguale per Debian e
Ubuntu (usa solo `apt`, `dpkg`, `tmux`, `ss` e `ip`).

- **Comandi pronti con la freccia su**, calcolati quando apri il terminale (basta `↑` e Invio):
  - se l'ultimo aggiornamento **non ha finito** (pacchetti a metà, dpkg interrotto, apt senza fine nel registro),
    il primo è lo sblocco che riprende tutto: `dpkg --configure -a && apt-get -f install && apt update && apt full-upgrade`,
    il secondo solo lo sblocco;
  - altrimenti il primo è **tutto attaccato**: `apt update && apt full-upgrade` (`full-upgrade` = upgrade e
    dist-upgrade in un colpo, chiede il Sì una volta sola);
  - se tra gli aggiornamenti c'è Docker, quello attaccato lo tiene fuori (`apt-mark hold`, poi `unhold`): Docker va
    fatto a parte, vedi sotto;
  - poi i soliti, uno per volta: `apt update`, `apt upgrade`, `apt dist-upgrade`.
  `lavori zero-comandi` li stampa nell'ordine in cui escono.
- **`lavori stato`** (lo mostra da solo anche quando apri il lavoro zero):
  - un `apt`/`dpkg` in corso, e se gira dentro tmux (sicuro) o fuori (se cade il collegamento si interrompe);
  - pacchetti rimasti a metà, dpkg interrotto, aggiornamento cominciato e mai finito: scrive i comandi per riprenderlo
    (`dpkg --configure -a && apt-get -f install`) e, dentro tmux, chiede se mandarlo avanti;
  - quanti pacchetti installerebbe davvero `apt-get upgrade` (prova a secco), quelli **trattenuti** (vogliono
    `dist-upgrade`) e, su Ubuntu, quelli **rimandati a scaglioni** («phased updates»: non è un guasto);
  - riavvio in sospeso; `needrestart` (su Ubuntu c'è di serie e dopo l'aggiornamento riavvia i servizi, Docker
    compreso: `NEEDRESTART_MODE=l` per vedere soltanto); aggiornamenti automatici accesi e riavvio automatico;
  - **Docker** (sotto).

#### Attenzione a Docker

Aggiornare `docker-ce`, `containerd.io`, `runc` & co. **riavvia Docker**: tutti i contenitori si fermano e ripartono
(anche quelli di Docker senza root) e **cade ogni connessione che passa da un contenitore**. Succede anche a chi sta
attento da anni, perché non sempre ci si ricorda che la propria connessione ci passa: una VPN, Tailscale, un proxy
o un tunnel che girano in un contenitore. Se ci passa anche l'SSH con cui stai aggiornando, l'aggiornamento si
interrompe a metà (dentro il lavoro zero almeno continua) e tu resti fuori finché Docker non è ripartito.
Dopo il riavvio, poi, non è detto che tutti i contenitori ripartano da soli: va controllato con `docker ps -a`.

Per questo `lavori stato`:
- guarda le connessioni SSH aperte e dice se una passa da Docker: interfaccia di una rete Docker (`docker0`, `br-*`)
  oppure un'interfaccia `tun` creata da un processo che sta in un contenitore (di cui dice il nome);
- se tra gli aggiornamenti c'è Docker, lo dice e propone l'ordine giusto: prima tutto il resto con Docker bloccato
  (`apt-mark hold …`), poi Docker da sola **da una strada che non passa da Docker** (console del provider o un'altra
  rete), poi il controllo dei contenitori;
- se Docker è installato come snap (Ubuntu), avvisa che si aggiorna e si riavvia da solo (`snap refresh --hold docker`).

### Guardia: le sessioni dimenticate aperte (facoltativo)
Se cade l'SSH e non ti ricolleghi, la sessione resta aperta con Claude dentro e nessuno te lo dice. La guardia
guarda proprio questo: le sessioni **staccate**, cioè aperte ma senza nessun terminale collegato.

```
lavori-guardia          # a mano: elenco delle sessioni staccate (guarda e basta)
lavori-guardia giro     # il giro di controllo, da far girare con cron
```

Per farla girare da sola ogni 5 minuti, crea `/etc/cron.d/lavori-guardia`:

```
3-59/5 * * * * root /usr/local/bin/lavori-guardia giro >/dev/null 2>&1
```

Un giro pesa pochissimo (circa 0,06 secondi: chiede a tmux chi è collegato e basta), quindi ogni 5 minuti non si
sente. Il `3-59/5` lo fa partire ai minuti 3, 8, 13…, lontano dallo scoccare dell'ora e dei dieci minuti, quando
di solito partono gli altri script.

Come si comporta il giro: la prima volta che vede una sessione staccata se la segna e aspetta (può essere uno
stacco di un attimo); se al giro dopo è ancora staccata manda il **primo avviso** (quindi entro 5-10 minuti dallo stacco), poi ricorda **ogni ora per le
prime 4 ore** e **ogni 4 ore** dopo. Quando ti ricolleghi o la chiudi dimentica tutto; se non c'è niente di
staccato sta zitta. Non chiude mai niente da sola.

Gli avvisi partono con il comando che metti in `LAVORI_AVVISA` (riceve il testo come ultimo argomento: lì
agganci il tuo bot Telegram o quello che usi); se sul sistema c'è un comando `avvisa` usa quello; se non c'è
niente, stampa il testo.

### Barra di stato tmux
Nelle sessioni aperte con `lavori` la barra in basso ha **tre righe**, tutte scritte per intero (la imposta `lavori`
stesso, e resta anche con la mod spenta):

```
[MioLavoro] mioserver 203.0.113.10 · 🧠 Opus 5.5 · 📦 contesto 461k/1.0M 46% · ⏳ abbonamento 5h 30% · 7gg 16% · Iacopo, 6 novembre 2026
 ⏱ 0h08m · ● 1 aperte · 💶 costo a listino: sessione 59 $ · questo lavoro ≈59 $ · 🪙 token del lavoro 73.2M · 📝 righe in sessione +292/-24
 ✍ lavoro vero (senza le pause): sessione 0h05m · questo lavoro 1h35m · tutti i lavori 102h · ✎ per la mod: iacopo off | on (ora on)
```

1. **Dove e con cosa**: la macchina (nome e indirizzo; `LAVORI_MACCHINA` la cambia o la toglie), il **modello** (cambia
   subito col `/model`; un **Fable** lampeggia a colori col 💰, un **Haiku** in bianco e nero; i modelli che per te
   sono a pagamento escono col 💰 se li scrivi, uno per riga, in `/etc/lavori/modelli-a-pagamento`), il **contesto**
   attuale sul limite del modello (⚠ oltre l'80%: è il momento di `/compact`), i **limiti dell'abbonamento** (finestra
   di 5 ore e settimana; ⚠ oltre l'80%), la firma.
2. **Quanto costa**: ⏱ da quanto è aperta la sessione, ● sessioni aperte, 💶 **costo a listino API** della sessione e
   del lavoro (anche con l'abbonamento dice quanto vale; a parte quello dei **sottoagenti**), 🪙 **token** del lavoro
   (tutti e quattro i tipi: ingresso, uscita, cache scritta, cache letta), 📝 righe cambiate in questa sessione.
3. **Tempo vero di lavoro**, calcolato dagli orari della conversazione (le pause di più di 1 minuto in cui nessuno
   scrive non contano): questa sessione, questo lavoro, tutti i lavori; per ultimo l'interruttore dello stile.

Da dove vengono i numeri: modello, contesto, limiti, costo e righe della sessione li passa Claude Code alla sua riga di
stato (`~/.claude/avviso-tmux.sh` li salva in `/etc/lavori/claude/<sessione>.json`); i conti del lavoro si fanno dalle
conversazioni salvate, coi prezzi che Claude Code tiene sulla macchina, con una cache (`attivo.cache`) che rilegge solo
la parte nuova. Se Claude Code ha compattato una conversazione, la sua storia vecchia può mancare: per questo il costo
del lavoro ha il ≈ e non scende mai sotto quello della sessione. Lo storico delle aperture resta in `lavori ore`.

Quando il terminale è troppo piccolo per i pannelli (meno di 120 colonne, o meno di 26 righe con la guida `plancia`),
davanti a tutto compare `⚠ metti a tutto schermo (ora 100x25)`; sparisce da solo quando lo allarghi.

Per le sessioni tmux che **non** apri con `lavori` puoi avere la stessa riga aggiungendo al tuo `~/.tmux.conf`:
```tmux
set -g status on
set -g status-interval 15
set -g status-left-length 220
set -g status-left '[#S] #(/usr/local/bin/lavori-barra #S)'
set -g status-right ''
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
- **Segnala + conferma**: aprendo un lavoro mentre un altro è ancora aperto, avvisa e chiede conferma.
- **"chiudi tutto" dal bot**: un comando per **chiudere tutte le sessioni da remoto** (dal telefono, via bot) se le
  hai lasciate aperte — la rete di sicurezza di uno strumento che altrimenti ti lascia tutto acceso.

## Licenza

MIT. Nessuna garanzia: lo usi a tuo rischio (vedi le avvertenze qui sopra).

---

✎ **Terminale personalizzato da Iacopo · 6 novembre 2026** — nome e data compaiono anche nella barra in basso di
ogni lavoro, accanto al nome della sessione (`LAVORI_FIRMA=""` toglie la scritta).
