#!/usr/bin/env python3
"""homelab-shell worker.

Long-polls the portfolio terminal API for whitelisted commands, executes
them against read-only host mounts, and posts the output back. Commands are
validated against a per-command flag allowlist and executed as fixed argv,
never through a shell, so visitor input cannot inject anything. The API
validates too; this is independent defense in depth.

top is a TUI: in interactive mode it runs in a pseudo-terminal for ~3s, pyte
emulates the screen, and the final frame is serialized back to ANSI text for
the web terminal. In batch mode (-b) it runs as a bounded subprocess.
"""

import fcntl
import json
import os
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time
import urllib.request

API_URL = os.environ.get("HOMELAB_API_URL", "").rstrip("/")
TOKEN = os.environ.get("HOMELAB_SHELL_TOKEN", "")

MAX_OUTPUT = 65_536
JOB_MAX_AGE_MS = 30_000

# --- Command registry + per-command flag validation (mirrors api/terminal.js)
NUM_RE = re.compile(r"^\d{1,6}(?:\.\d+)?$")
WORD_RE = re.compile(r"^[A-Za-z0-9_.,%+:-]+$")  # no slash => no filesystem paths
COMMANDS = {
    "whoami": {"short": "", "positional": "none"},
    "id": {"short": "ugGnrz", "positional": "none"},
    "groups": {"short": "", "positional": "none"},
    "uname": {"short": "armnsvpio", "positional": "none"},
    "uptime": {"short": "ps", "positional": "none"},
    "hostname": {"short": "Iifsd", "positional": "none"},
    "arch": {"short": "", "positional": "none"},
    "nproc": {"short": "", "long": {"--all": 0, "--ignore": 1}, "positional": "none"},
    "pwd": {"short": "", "positional": "none"},
    "logname": {"short": "", "positional": "none"},
    "tty": {"short": "s", "positional": "none"},
    "users": {"short": "", "positional": "none"},
    "who": {"short": "abdHilmpqrstTuw", "positional": "none"},
    "w": {"short": "husfoi", "positional": "none"},
    "cal": {"short": "13smjwyV", "positional": "num", "maxPos": 3},
    "date": {"short": "uR", "long": {"--utc": 0, "--rfc-2822": 0, "--rfc-3339": 0, "--iso-8601": 0}, "plus": True, "positional": "none"},
    "df": {"short": "hHkmgGTilPa", "valueShort": {"t": "word", "x": "word", "B": "word"}, "long": {"--total": 0, "--human-readable": 0, "--si": 0, "--inodes": 0, "--local": 0, "--portability": 0, "--print-type": 0, "--no-sync": 0, "--type": 1, "--exclude-type": 1, "--block-size": 1}, "positional": "none"},
    "free": {"short": "hmkgtb", "valueShort": {"s": "num", "c": "num"}, "long": {"--human": 0, "--mega": 0, "--giga": 0, "--kilo": 0, "--bytes": 0, "--total": 0, "--loose": 0, "--wide": 0, "--seconds": 1, "--count": 1}, "positional": "none"},
    "lsblk": {"short": "abDdfilmMnJOPprstTSV", "valueShort": {"o": "word", "x": "word", "e": "num"}, "long": {"--all": 0, "--bytes": 0, "--discard": 0, "--nodeps": 0, "--exclude": 1, "--fs": 0, "--ascii": 0, "--json": 0, "--list": 0, "--merge": 0, "--perms": 0, "--noheadings": 0, "--output": 1, "--output-all": 0, "--pairs": 0, "--paths": 0, "--raw": 0, "--scsi": 0, "--inverse": 0, "--topology": 0, "--tree": 0, "--sort": 1}, "positional": "none"},
    "lscpu": {"short": "abcepsJBy", "long": {"--all": 0, "--online": 0, "--offline": 0, "--bytes": 0, "--caches": 0, "--extended": 0, "--parse": 0, "--json": 0}, "positional": "none"},
    "vmstat": {"short": "adfstw", "valueShort": {"S": "word", "p": "word"}, "long": {"--active": 0, "--disk": 0, "--forks": 0, "--slabs": 0, "--stats": 0, "--timestamp": 0, "--unit": 1, "--wide": 0, "--partition": 1}, "positional": "num", "maxPos": 2},
    "fastfetch": {"short": "", "positional": "none"},
    "echo": {"any": True, "noMeta": True},
    "top": {"short": "bdisSH", "valueShort": {"d": "num", "n": "num", "o": "word", "w": "num", "p": "num", "u": "word"}, "blockShort": "c", "long": {"--batch": 0, "--delay": 1, "--iterations": 1, "--sort": 1, "--width": 1, "--pid": 1, "--user": 1}, "positional": "none"},
}


def value_ok(kind, val):
    if not val:
        return False
    return bool(NUM_RE.match(val) if kind == "num" else WORD_RE.match(val))


def validate_args(spec, tokens):
    pos = 0
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in ("--help", "--version"):
            i += 1
            continue  # allowed, but keep validating the rest
        if spec.get("noMeta") and re.search(r"[><|&;`$()\\]", tok):
            return "shell metacharacters not allowed"
        if spec.get("any"):
            i += 1
            continue
        if tok.startswith("--"):
            eq = tok.find("=")
            name = tok if eq < 0 else tok[:eq]
            eq_val = None if eq < 0 else tok[eq + 1:]
            long = spec.get("long", {})
            if name not in long:
                return f"flag not allowed: {name}"
            if eq_val is not None:
                if not value_ok("word", eq_val):
                    return f"bad value for {name}"
            elif long[name] == 1:
                nxt = tokens[i + 1] if i + 1 < len(tokens) else None
                if not value_ok("word", nxt) and not value_ok("num", nxt):
                    return f"{name} needs a value"
                i += 1
            i += 1
            continue
        if tok.startswith("-") and len(tok) > 1:
            chars = tok[1:]
            consumed_next = False
            for j, c in enumerate(chars):
                if c in spec.get("blockShort", ""):
                    return f"flag not allowed: -{c}"
                vs = spec.get("valueShort", {})
                if c in vs:
                    val = chars[j + 1:]
                    if val == "":
                        val = tokens[i + 1] if i + 1 < len(tokens) else None
                        consumed_next = True
                    if not value_ok(vs[c], val):
                        return f"bad value for -{c}"
                    break
                if c not in spec.get("short", ""):
                    return f"flag not allowed: -{c}"
            if consumed_next:
                i += 1
            i += 1
            continue
        if tok.startswith("+") and spec.get("plus"):
            i += 1
            continue
        if spec.get("positional") == "none":
            return f"unexpected argument: {tok}"
        if not value_ok(spec["positional"], tok):
            return f"bad argument: {tok}"
        pos += 1
        if pos > spec.get("maxPos", 1):
            return "too many arguments"
        i += 1
    return None


def validate_command(raw):
    if not isinstance(raw, str):
        return {"error": "bad command"}
    trimmed = " ".join(raw.split())
    if not trimmed or len(trimmed) > 256:
        return {"error": "bad command"}
    parts = trimmed.split(" ", 1)
    name = parts[0].lower()
    args_str = parts[1] if len(parts) > 1 else ""
    spec = COMMANDS.get(name)
    if spec is None:
        return {"error": "command not allowed"}
    tokens = args_str.split(" ") if args_str else []
    if len(tokens) > 24:
        return {"error": "too many arguments"}
    err = validate_args(spec, tokens)
    if err:
        return {"error": err}
    return {"command": name + (" " + args_str if args_str else "")}


def log(msg):
    print(f"[homelab-shell] {msg}", flush=True)


def http(method, url, payload=None, timeout=15):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def run_argv(argv, timeout=12):
    proc = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
    out = proc.stdout
    if proc.returncode != 0 and proc.stderr:
        out += proc.stderr
    return out, proc.returncode


def run_fastfetch(args):
    if args:  # only --help/--version pass validation
        return run_argv(["fastfetch"] + args)
    out, code = run_argv(["fastfetch", "--config", "/app/fastfetch.jsonc"])
    return out.replace("(/host)", "(/)"), code


def run_df(args):
    out, code = run_argv(["df"] + args + ["/host"])
    lines = out.splitlines()
    if lines:
        lines = [ln[:-5] + "/" if ln.endswith("/host") else ln for ln in lines]
    return "\n".join(lines) + "\n", code


def run_hostname(args):
    if args:
        return run_argv(["hostname"] + args)
    try:
        with open("/host/etc/hostname") as f:
            return f.read().strip() + "\n", 0
    except OSError as exc:
        return f"hostname: {exc}\n", 1


# --- top TUI snapshot ------------------------------------------------------

# pyte stores basic colors as names, 256-colors as hex strings
NAMED_FG = {
    "black": 30, "red": 31, "green": 32, "brown": 33, "yellow": 33,
    "blue": 34, "magenta": 35, "cyan": 36, "white": 37,
    "brightblack": 90, "brightred": 91, "brightgreen": 92,
    "brightyellow": 93, "brightblue": 94, "brightmagenta": 95,
    "brightcyan": 96, "brightwhite": 97, "gray": 90,
}


def color_code(color, base):
    if color == "default":
        return None
    if color in NAMED_FG:
        return str(NAMED_FG[color] + (base - 30))
    if isinstance(color, str) and len(color) == 6:
        try:
            r, g, b = int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16)
            return f"{base};2;{r};{g};{b}"
        except ValueError:
            return None
    return None


def sgr(fg, bg, bold):
    codes = ["0"]
    if bold:
        codes.append("1")
    fg_code = color_code(fg, 38)
    if fg_code:
        codes.append(fg_code)
    bg_code = color_code(bg, 48)
    if bg_code:
        codes.append(bg_code)
    return "\x1b[" + ";".join(codes) + "m"


def serialize_screen(screen):
    rows = []
    for y in range(screen.lines):
        row = screen.buffer[y]
        parts = []
        cur = None
        for x in range(screen.columns):
            ch = row[x]
            style = (ch.fg, ch.bg, ch.bold)
            if style != cur:
                parts.append(sgr(*style))
                cur = style
            parts.append(ch.data if ch.data else " ")
        rows.append("".join(parts).rstrip() + "\x1b[0m")
    while rows and not rows[-1].replace("\x1b[0m", "").strip():
        rows.pop()
    return "\n".join(rows) + "\n"


def run_top_tui(args):
    import pyte

    rows, cols = 40, 120
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.environ["HOME"] = "/tmp"
        os.execvp("top", ["top"] + args)

    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    screen = pyte.Screen(cols, rows)
    stream = pyte.Stream(screen)

    deadline = time.time() + 3.0
    while time.time() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if not ready:
            continue
        try:
            data = os.read(fd, 65536)
        except OSError:
            break
        if not data:
            break
        stream.feed(data.decode("utf-8", "replace"))

    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        os.close(fd)
    except OSError:
        pass
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass

    return serialize_screen(screen), 0


def run_top(args):
    batch = "-b" in args or "--batch" in args or any(
        a.startswith("-") and not a.startswith("--") and "b" in a[1:] for a in args
    )
    if batch:
        a = list(args)
        has_n = any(
            a == "--iterations" or a.startswith("--iterations=")
            or (a.startswith("-") and not a.startswith("--") and "n" in a[1:])
            for a in a
        )
        if not has_n:
            a += ["-n", "1"]  # bound batch mode so it cannot run forever
        return run_argv(["top"] + a, timeout=12)
    return run_top_tui(args)


# --- dispatch --------------------------------------------------------------

def execute(command):
    v = validate_command(command)
    if "error" in v:
        return f"{v['error']}\n", 126
    parts = v["command"].split(" ")
    cmd, args = parts[0], parts[1:]

    if cmd == "fastfetch":
        return run_fastfetch(args)
    if cmd == "top":
        return run_top(args)
    if cmd == "df":
        return run_df(args)
    if cmd == "hostname":
        return run_hostname(args)
    if cmd == "lsblk":
        out, code = run_argv(["lsblk"] + args)
        out = out.replace("/host/", "/").replace(" /host\n", " /\n")
        return out, code
    return run_argv([cmd] + args)


def main():
    if not API_URL or not TOKEN:
        log("HOMELAB_API_URL and HOMELAB_SHELL_TOKEN must be set (see .env.example)")
        sys.exit(1)
    log(f"polling {API_URL} for commands")

    idle = 0
    while True:
        try:
            resp = http("GET", API_URL + "?worker=poll", timeout=12)
            job = resp.get("job")
        except Exception as exc:
            log(f"poll failed: {exc}")
            time.sleep(3)
            continue

        if not job:
            idle += 1
            # Idle backoff: BLPOP already blocks 5s server-side; add up to
            # 5s more so an idle lab costs ~1 command/10s, not 1/5s
            # (Upstash daily command budget). Resets when work arrives.
            time.sleep(min(5.0, 0.3 * idle))
            continue

        idle = 0

        if time.time() * 1000 - job.get("createdAt", 0) > JOB_MAX_AGE_MS:
            log(f"dropping stale job {job.get('id')}")
            continue

        command = job.get("command", "")
        job_id = job.get("id", "")
        started = time.time()
        try:
            output, code = execute(command)
        except subprocess.TimeoutExpired:
            output, code = "command timed out\n", 124
        except Exception as exc:
            output, code = f"error: {exc}\n", 1
        log(f"ran {command!r} -> exit {code} in {time.time() - started:.1f}s")

        try:
            http("POST", API_URL, {
                "action": "result",
                "id": job_id,
                "command": command,
                "output": output[:MAX_OUTPUT],
                "exitCode": code,
            })
        except Exception as exc:
            log(f"result post failed: {exc}")


if __name__ == "__main__":
    main()
