# Unix sockets, and a remote PTY server with a UI client

## 1. What a Unix domain socket is

A Unix socket works like a TCP socket, but both ends are on the same machine and the address is a file path instead of `host:port`:

```
TCP:   connect("10.0.0.5", 8080)
Unix:  connect("/tmp/tmux-501/default")
```

- **The server** calls `socket(AF_UNIX, SOCK_STREAM)`, then `bind("/path/to/sock")`, `listen()`, and `accept()` in a loop. Each `accept()` returns a new connection, one per client.
- **The client** calls `socket(AF_UNIX, ...)` and `connect("/path/to/sock")`, then reads and writes bytes.
- The kernel copies bytes directly between the two processes. There's no network stack, so it's fast.
- **Permissions** are ordinary file permissions on the socket file, so `chmod 700` on the directory means only you can connect.
- **Extras TCP doesn't have:**
  - You can pass open file descriptors to the other process (`SCM_RIGHTS`). tmux uses this to hand your terminal to the server.
  - You can ask the kernel who is on the other end (peer uid/pid).

**The catch for this tool:** Unix sockets are local only. A client on a laptop can't `connect()` to a socket on a remote server directly. It needs a bridge (see section 4).

tmux is exactly this design:

```
$ ls -la /tmp/tmux-$(id -u)/
srwxrwx---  default      ← the "s" means socket
```

- `tmux attach` is a small client that connects to that socket.
- The tmux **server** process owns all the PTYs.
- Closing the terminal leaves the server and its sessions running.

## 2. What a PTY is

A pseudo-terminal is a pair of file descriptors:

```
            ┌──────────── PTY ────────────┐
 your code ─┤ master fd        slave fd   ├─ shell (zsh, nvim, claude)
            └─────────────────────────────┘
 write(master, "ls\r")  → the shell reads "ls\n" as if you typed it
 read(master)           ← everything the shell prints (text + ANSI escape codes)
 ioctl(master, TIOCSWINSZ, rows, cols) → the shell gets SIGWINCH and redraws
```

The process that holds the master fd controls the program. So in this design, the **server** holds the masters.

## 3. Architecture

```
 ┌─────────── remote host ────────────┐          ┌──────── your laptop ───────┐
 │                                    │          │                            │
 │  maestrod (server, long-lived)     │          │  maestro (client, UI)      │
 │  ┌──────────────────────────────┐  │          │                            │
 │  │ state: sessions/windows/panes│  │  framed  │  - renders panes           │
 │  │ pane 1 ── PTY ── nvim        │◄─┼─messages─┼─► - captures keystrokes    │
 │  │ pane 2 ── PTY ── zsh         │  │  over a  │  - sends commands          │
 │  │ pane 3 ── PTY ── claude      │  │  stream  │                            │
 │  └──────────────────────────────┘  │          │                            │
 │  listens on ~/.maestro/sock        │          │                            │
 └────────────────────────────────────┘          └────────────────────────────┘
```

**The server is the source of truth.** The client is a view plus an input device. It can crash, disconnect, or reconnect from another machine, and nothing is lost. This is the tmux model.

## 4. Getting from the laptop to the remote socket

Pick one of these:

1. **SSH as the transport (recommended to start).** Auth and encryption come for free.
   ```
   ssh -L /tmp/maestro-remote.sock:/home/me/.maestro/sock host   # forward the socket
   # or simpler: run a relay on the remote that bridges stdin/stdout ↔ the socket
   ssh host maestrod --relay        # the client talks to ssh's stdin/stdout
   ```
   The second form is how `ssh host tmux -CC` (iTerm2) and VS Code Remote work.
2. **TCP + TLS** on the server. Auth then has to be handled by the tool itself.
3. **WebSocket**, for a possible browser client.

Design the protocol over a **generic byte stream** and the transport becomes swappable. A Unix socket, an SSH pipe, and TCP all look identical to the code.

## 5. The protocol: framed messages

A stream socket delivers bytes, not messages. Two `write`s can arrive as one `read`, or one `write` can arrive split in half. So each message is framed:

```
┌──────────┬──────────┬─────────────────────┐
│ len (u32)│ type (u8)│ payload (len bytes) │
└──────────┴──────────┴─────────────────────┘
```

For the payload, use JSON or msgpack for control messages. For PTY data, send raw bytes or msgpack binary, not base64-in-JSON on the hot path.

Messages are either **requests** (client to server, carry an `id`), **responses** (carry the same `id`), or **events** (server to client, unsolicited).

```
Client → Server                          Server → Client
───────────────                          ───────────────
Hello{version, client_size}              Welcome{version}
Attach{session}                          Snapshot{full state tree + screen contents}
Input{pane_id, bytes}                    Output{pane_id, bytes}      ← the hot path
Resize{pane_id or client, cols, rows}    PaneExited{pane_id, code}
Cmd{id, NewWindow{session, name, cmd}}   Result{id, ok | error}
Cmd{id, SplitPane{pane, dir}}            StateChanged{diff or new tree}
Cmd{id, RenameWindow{...}}
Cmd{id, KillPane{...}}
Detach{}
```

## 6. Sending keys from client to server

1. Put the client's local terminal in **raw mode** (`cfmakeraw`) so every keystroke arrives immediately. No line buffering, and Ctrl-C comes through as a byte instead of a signal.
2. Read bytes from stdin. Check for the **prefix key** (like tmux's `Ctrl-b`):
   - If it's a UI command (switch pane, split, detach), handle it locally or send a `Cmd`.
   - Otherwise send `Input{pane_id: focused, bytes}`.
3. The server does `write(pty_master[pane_id], bytes)`. That's all it does with input.

Send **raw bytes**, not parsed key names. Arrow keys, Alt combos, mouse events, and bracketed paste are already encoded as escape sequences (`\x1b[A` is Up), and the program in the pane expects exactly those bytes. Only parse the bytes that need intercepting, such as the prefix key.

## 7. Getting the screen from server to client

This is the real design decision. There are two options.

**A) Stream raw PTY output; the client emulates the terminal** (Zellij-web and WezTerm's mux do variants of this)
- The server reads the PTY and forwards `Output{pane, bytes}` as-is.
- The client runs one terminal emulator per pane (vt100 parser plus screen grid, e.g. `vte`/`alacritty_terminal` in Rust or `xterm.js` on the web) and composites the panes into its UI.
- ✅ Simple server, low latency, and the client can use a GUI or web renderer.
- ❌ On reconnect, the client doesn't know what's on screen. The server has to keep a **scrollback/replay buffer**, or run its own emulator anyway so it can send a snapshot.

**B) The server emulates; it sends screen diffs** (how tmux and mosh work)
- The server parses PTY output into a cell grid per pane.
- The server sends "cells changed in rows 5–7" or a rendered frame.
- ✅ Reconnect is trivial (send the current grid), bandwidth is bounded on slow links, and mosh-style prediction becomes possible.
- ❌ More server work, and correctness depends on the server's emulator being accurate.

**Recommendation:** run an emulator on the server regardless, because it's the only way to get a clean snapshot on attach. Start with (A) for live updates and send a server-rendered snapshot on attach. Move to (B) later if bandwidth or latency over bad links becomes a problem.

## 8. Changing sessions from the client

The client never changes state itself. It **asks**, and the server **decides and broadcasts**:

```
client: Cmd{id:7, SplitPane{pane:"p3", dir:"vertical", cmd:"zsh"}}
server: - forkpty() a new zsh
        - update the layout tree
        - Result{id:7, ok, pane:"p9"}                ← to the requester
        - StateChanged{session tree}                 ← to ALL attached clients
client: re-renders from the new tree
```

This gives, for free:
- **Multiple clients** see the same thing (e.g. a laptop and a desktop attached at once).
- **No drift**, because clients only render what the server says.
- **Scripting**: a CLI like `maestro new-window -s x` is just another client that sends one `Cmd` and exits. That's what `tmux new-window` does.

A TOML session file fits in naturally as a declarative spec: `maestro apply session.toml` turns into a series of `Cmd`s. The server can also serialize its state back to TOML for save/restore. Example:

```toml
[session]
name = "ide-ivanm-maestro"
root = "/Users/ivanm/git/maestro"
active_window = "agent"

[[session.windows]]
index = 1
name = "editor"

  [[session.windows.panes]]
  command = "nvim ."
  shell_after = true

[[session.windows]]
index = 2
name = "terminal"

[[session.windows]]
index = 3
name = "henv"

  [[session.windows.panes]]
  command = "henv"
  shell_after = true

[[session.windows]]
index = 4
name = "agent"

  [[session.windows.panes]]
  command = "claude"
  shell_after = true
```

## 9. Server event loop

```
loop over ready fds (epoll/kqueue, or goroutines/tokio tasks):
  listener readable     → accept new client
  client readable       → parse frames → Input: write(pty) | Resize: ioctl | Cmd: mutate + broadcast
  pty master readable   → read bytes → feed pane emulator → send Output to attached clients
  SIGCHLD               → reap the process → PaneExited → update state → broadcast
```

## 10. Pitfalls to plan for

- **Resize with several clients:** clients have different terminal sizes. tmux uses the smallest client, or the most recently active one. Pick a rule.
- **Backpressure:** `cat bigfile` in a pane with a slow client attached. Don't buffer without limit. Drop to snapshot mode or pause reading the PTY.
- **Detach vs kill:** a client closing its connection must **never** kill panes.
- **Versioning:** put a protocol version in `Hello` from day one.
- **Daemonizing:** the server must survive the SSH session ending (`setsid`, or start it via systemd/launchd).

## Suggested build order

1. A local-only server with one PTY and a raw-mode client over a Unix socket, just piping bytes. That's about 200 lines and already useful.
2. Add framing and message types, plus multiple panes and a `Cmd` for new pane/window.
3. Add a server-side emulator and snapshot on attach, so detach/reattach works.
4. Add the SSH stdio relay, so it works remotely.
5. Add layout, multiple clients, and TOML apply/save.
