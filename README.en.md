# claude-code-terminale-tmux

🇮🇹 [Italiano](README.md) · 🇬🇧 **English**

Shell scripts for **Claude Code in the terminal**: one project per **tmux** session, sessions that **survive a
dropped SSH connection**, and an **index of your work** to create and reopen projects with a single command.

The command is called `lavori` (Italian for "jobs/works"); the tool's messages are in Italian.

```
$ lavori
  ═══ Lavori di Claude Code ═══
   1) ● aperto  server       Server: maintenance
      /root · ultimo uso: 2026-11-03 09:12
   2) ○ chiuso  sito         Company website
      /srv/sito · ultimo uso: 2026-11-02 18:40

  [numero] apri   n nuovo lavoro   i dettagli   ? come funziona   a guida completa   q esci
  Scelta:
```
(`aperto` = open, `chiuso` = closed, `apri` = open it, `nuovo lavoro` = new project, `esci` = quit.)

---

## ⚠️ First of all: this is NOT for everyone

This tool is **very handy**, but also **dangerous**. It is meant for people who **administer a server** and know
what it means to leave a Claude Code session running, usually as **root**. If you don't know what tmux is, what
root permissions imply and what the risks of an unattended session are, **don't use it**.

**The risks, plainly:**

1. **Sessions stay open on purpose.** Claude Code keeps running inside tmux after you disconnect. Anyone who gets
   onto the machine as the same user (or as root), or reaches the tmux socket, **can attach and find Claude ready**,
   with all the permissions of that session.
2. **It brings back what you were doing.** The tmux scrollback keeps commands, answers and output, **including
   secrets** pasted or printed by mistake (passwords, keys, tokens). Whoever attaches can see them.
3. **Reopening a project resumes the whole conversation.** `lavori <name>` resumes the latest Claude conversation in
   that folder, with all its content and context.
4. **It separates CONTEXT, not PERMISSIONS.** Each project has its own history and memory, but running as root a
   project can still read and change other projects' folders. The separation relies on the instructions
   (`CLAUDE.md`) and on whoever is working, not on a technical barrier.
5. **The index tells where to look.** Conversations are stored in `~/.claude/projects/` (Claude Code does that by
   itself); the index lists folders and descriptions, so it is information to protect (it is `600`, root only).

**Good practice:** SSH with keys only, firewall on SSH, no shared users, close the sessions you don't use (`/exit`
in Claude, then Enter), don't paste secrets in the terminal, and remember that `tmux ls` shows everything open.

---

## How it works

- **The folder separates projects.** Claude Code keeps conversations and memory **per working directory**
  (`~/.claude/projects/<folder>/`) and reads the folder's `CLAUDE.md` at startup. Different folders = different
  contexts: in one project Claude doesn't see the history of the others.
- **tmux keeps the session alive.** If the connection drops, Claude keeps running and you reattach. Each project has
  its own tmux session, so you can have several open and switch between them.
- **`lavori` ties the two together** and keeps an index of what exists, where it is and when you last used it.

## The easy way: the menu

Just type **`lavori`** in the terminal:

- **a number** (or the name): open that project;
- **n**: new project, with guided questions (name, folder, description); at the end it opens it;
- **i**: project details (folder, `CLAUDE.md`, memory, conversations with their ids);
- **?**: how it works, in five lines; **a**: the full guide; **q**: quit.

The first time, when there are no projects yet, the menu explains what it is and how to start.

**So you don't forget it:** with `sudo ./installa.sh --promemoria`, when you log in via SSH outside tmux two lines
remind you to use `lavori` and show which projects are already open (file `/etc/profile.d/lavori-promemoria.sh`).

## Commands

| Command | What it does |
|---|---|
| `lavori` | the **menu** (in a terminal); from a script or a pipe it prints the list |
| `lavori elenco` | just the list: state (● open, closed, ✗ missing folder), folder, last use, description |
| `lavori <name>` | opens the project: reattaches to its tmux session, or creates it in the right folder and starts Claude resuming **the latest conversation** (`--continue`) |
| `lavori <name> <id>` | same, but resumes that conversation (`--resume <id>`) |
| `lavori nuovo <name> <folder> "description"` | creates the project: folder and a starter `CLAUDE.md` (if missing) and the index entry |
| `lavori info <name>` | details: folder, `CLAUDE.md`, memory, latest conversations with id, date and size |
| `lavori descrivi <name> "description"` | changes the description |
| `lavori togli <name>` | removes it from the index (asks first); **does not delete** the folder or conversations |
| `lavori promemoria` | the two login lines: open projects and how to use it |
| `lavori aiuto` | the guide |

Inside tmux: **Ctrl-b d** detaches without closing anything, **Ctrl-b s** switches to another project.
If you run `lavori <other>` while already in tmux, it switches session instead of nesting.

**Checks:** names only lowercase, digits, `-` and `_`; no duplicate names; **a folder cannot belong to two
projects** (it would be the same Claude context); no system folders (`/`, `/etc`, `/usr`…); conversation id
validated; warning if a tmux session with that name already exists outside the index.

## Files

| What | Where |
|---|---|
| command | `/usr/local/bin/lavori` |
| index | `/etc/lavori/indice.tsv` (name, tmux session, folder, created, last use, description); on every change a copy in `indice.tsv.prima`, write to a temp file, lock with `flock` |
| log | `/var/log/lavori.log` (opens, creations, removals) |
| status line | `~/.claude/avviso-tmux.sh` (optional, see below) |

Paths can be changed with the variables `LAVORI_DIR`, `LAVORI_REGISTRO`, `CLAUDE_BIN`, `PROGETTI_CLAUDE`.

## Installation

Requires: Linux, `bash`, `tmux`, `flock` (util-linux), Claude Code already installed. Run as **root**.

```bash
git clone https://github.com/iacopo-cmd/claude-code-terminale-tmux.git
cd claude-code-terminale-tmux
sudo ./installa.sh --promemoria   # without --promemoria: no login message
lavori                           # menu: n = new project
```

### Status line and warnings (optional)

`avviso-tmux.sh` shows in Claude Code's status line which session you are in and what to run again
(`● tmux "server": se cade la linea rilancia lavori server` = "if the connection drops, run lavori server again").
If Claude is **not** running inside tmux it shows a red warning instead, plus a few reminders in the chat.
`installa.sh` copies it to `~/.claude/`; to enable it **add by hand** the content of `impostazioni-esempio.json` to
your `~/.claude/settings.json`, without overwriting your existing settings.

## License

MIT. No warranty: use it at your own risk (see the warnings above).
