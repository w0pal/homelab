#!/usr/bin/env python3
"""homelab-shell worker.

Long-polls the portfolio terminal API for whitelisted commands, executes
them against read-only host mounts, and posts the output back. Commands
are matched against a fixed whitelist and executed as fixed argv — never
through a shell, so visitor input cannot inject anything.

btop is a TUI with no batch mode: it runs in a pseudo-terminal for ~3s,
pyte emulates the screen, and the final frame is serialized back to ANSI
text for the web terminal.
"""

import fcntl
import json
import os
import pty
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

ALLOWED = {
    "fastfetch", "btop", "df -h", "free -h", "uptime",
    "uname -a", "hostname", "date", "lsblk",
}

MAX_OUTPUT = 65_536
JOB_MAX_AGE_MS = 30_000


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


def run_fastfetch():
    out, code = run_argv(["fastfetch", "--config", "/app/fastfetch.jsonc"])
    return out.replace("(/host)", "(/)"), code


def run_df():
    out, code = run_argv(["df", "-h", "/host"])
    lines = out.splitlines()
    if lines:
        # Present the host root mount as "/" instead of "/host"
        lines = [ln[:-5] + "/" if ln.endswith("/host") else ln for ln in lines]
    return "\n".join(lines) + "\n", code


def run_hostname():
    try:
        with open("/host/etc/hostname") as f:
            return f.read().strip() + "\n", 0
    except OSError as exc:
        return f"hostname: {exc}\n", 1


# --- btop snapshot ---------------------------------------------------------

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


def run_btop():
    import pyte

    rows, cols = 40, 120
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.environ["HOME"] = "/tmp"
        os.execvp("btop", ["btop"])

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


# --- dispatch --------------------------------------------------------------

def execute(command):
    if command == "fastfetch":
        return run_fastfetch()
    if command == "btop":
        return run_btop()
    if command == "df -h":
        return run_df()
    if command == "free -h":
        return run_argv(["free", "-h"])
    if command == "uptime":
        return run_argv(["uptime"])
    if command == "uname -a":
        return run_argv(["uname", "-a"])
    if command == "hostname":
        return run_hostname()
    if command == "date":
        return run_argv(["date"])
    if command == "lsblk":
        return run_argv(["lsblk"])
    return f"command not allowed: {command}\n", 126


def main():
    if not API_URL or not TOKEN:
        log("HOMELAB_API_URL and HOMELAB_SHELL_TOKEN must be set (see .env.example)")
        sys.exit(1)
    log(f"polling {API_URL} for commands")

    while True:
        try:
            resp = http("GET", API_URL + "?worker=poll", timeout=12)
            job = resp.get("job")
        except Exception as exc:
            log(f"poll failed: {exc}")
            time.sleep(3)
            continue

        if not job:
            time.sleep(0.3)
            continue

        if time.time() * 1000 - job.get("createdAt", 0) > JOB_MAX_AGE_MS:
            log(f"dropping stale job {job.get('id')}")
            continue

        command = job.get("command", "")
        job_id = job.get("id", "")
        if command not in ALLOWED:
            output, code = f"command not allowed: {command}\n", 126
        else:
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
