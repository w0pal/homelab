# My Homelab

This repository contains the GitOps configuration for my personal homeserver.
It started as a hobby project, and I now use it for development too. I also use
it as a semi staging box: I try changes here first, then carry the ones that
work over to deployment. It still runs services for fun and personal
convenience (media, passwords, network tools). It is not a production
environment.

I don't aim for perfection here (seriously). Things will change often as I experiment and
figure out better ways to manage this. This repo works both as
documentation for myself and as something others can look at to learn from. If you
find something useful, feel free to use it in your own projects.

The setup includes a mix of media services, personal productivity tools, and
infrastructure components. Some are for fun, some are for convenience, and
others are just experiments. Nothing here is production grade. It is my weekend
project.

Feel free to explore and see how everything is set up. If you have any
questions or suggestions, you can reach out to me on GitHub (w0pal). If I can help you with something, I
will be happy to do so.

---

# Installed Apps

The tables below show what is live on `takamatsu`. Retired experiments live in `docs/retired-experiments.md`.

<h2>🛡️ Infrastructure</h2>
<table>
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/adguard-home.svg" width="32" /></td>
        <td>AdGuard Home</td>
        <td>DNS-level ad and tracker blocker for your entire network with custom rewrites (vault.local, lab.tailf2af36.ts.net, etc.)</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/nginx.svg" width="32" /></td>
        <td>Nginx Proxy Manager</td>
        <td>Reverse proxy with web UI for managing proxy hosts, SSL certificates, and access lists</td>
    </tr>
</table>

<h2>🔐 Security & Passwords</h2>
<table>
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/vaultwarden.svg" width="32" /></td>
        <td>Vaultwarden</td>
        <td>Lightweight Bitwarden-compatible password manager with WebSocket support for live sync</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/podman.svg" width="32" /></td>
        <td>DVWA</td>
        <td>Damn Vulnerable Web Application lab with its own MariaDB, bound to 127.0.0.1:8081 so only the host can reach it</td>
    </tr>
</table>

<h2>🌐 Remote Access</h2>
<table>
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/tailscale.svg" width="32" /></td>
        <td>Tailscale</td>
        <td>WireGuard-based mesh VPN for secure remote access (HTTPS via serve)</td>
    </tr>
</table>

<h2>☁️ Storage & Docs</h2>
<table>
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/nextcloud.svg" width="32" /></td>
        <td>Nextcloud</td>
        <td>File sync and sharing with MariaDB, Redis and a storage watcher; served at nextcloud.lab via NPM</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/file.svg" width="32" /></td>
        <td>Wordcraft</td>
        <td>Static writing web app plus a file API on ports 8090 and 8091</td>
    </tr>
</table>

<h2>🤖 Homelab Helpers</h2>
<table>
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/terminal.svg" width="32" /></td>
        <td>homelab-shell</td>
        <td>Read-only shell worker that polls the portfolio API for jobs</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/server.svg" width="32" /></td>
        <td>homelab-fetch</td>
        <td>Read-only stats collector that pushes fastfetch output from the host to the portfolio Now page</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/robot.svg" width="32" /></td>
        <td>Hermes Gateway</td>
        <td>Discord bot runtime under OpenRC; shares skills from ~/.agents/skills</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/router.svg" width="32" /></td>
        <td>9router / portfolio-api</td>
        <td>Routing daemon and portfolio API, both managed by OpenRC</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/server.svg" width="32" /></td>
        <td>paseo</td>
        <td>Paseo daemon (local AI agent control plane)</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/server.svg" width="32" /></td>
        <td>kanaos</td>
        <td>Minimal self-hosted dashboard on port 3008 with a read-only Podman socket</td>
    </tr>
</table>

---

## Network Architecture

```
Internet / Tailscale
        │
        ▼
Nginx Proxy Manager (192.168.0.240:80, :443, :81)
        │
        ├── Vaultwarden (192.168.0.240:8080)
        └── Nextcloud (:80 internal, shared-web)

Direct ports:
        Wordcraft web :8090, file API :8091
        kanaos dashboard :3008
        DVWA 127.0.0.1:8081 (host only)
```

## Service Details

| Service | Port(s) | Network | Health Check |
|---------|---------|---------|--------------|
| AdGuard Home | 53 (DNS), 3000 (Web) | host | Built-in |
| Nginx Proxy Manager | 80, 443, 81 (Admin) | `shared-web` | Auto |
| Vaultwarden | 8080 (internal) | `shared-web` | `/alive` endpoint |
| Nextcloud | 80 (via NPM) | `nextcloud_backend`, `shared-web` | MariaDB healthcheck |
| Wordcraft | 8090, 8091 | bridge | none |
| DVWA | 8081 (127.0.0.1) | `dvwa_default` | none |
| homelab-shell | none (outbound only) | `homelab-shell_default` | none |
| homelab-fetch | none (outbound only) | `homelab-fetch_default` | none |
| kanaos | 3008 | bridge | none |

---

## Quick Start

### Prerequisites
- Podman and podman-compose
- Tailscale (for remote HTTPS)
- A domain or Tailscale MagicDNS name

### Deploy All Services

If you are using an AI to clone or troubleshoot this host, read
`docs/ai-rules.md` first. `AGENTS.md` has the install flow for another machine.
Private work or professional projects must never
enter this repo, the inventory, bootstrap, or commit messages.

```bash
# Clone this repo
git clone https://github.com/w0pal/homelab.git
cd homelab

# Apply host config from a fresh clone
sudo ./bootstrap.sh --apply

# Optional: install packages and start active compose services
sudo ./bootstrap.sh --apply --packages --containers
```

### Pinned CLI tools (Nix)

A flake pins userland tools such as btop, eza, fd, ripgrep, yazi, PHP, Go, Claude Code, Codex, Paseo and 9router. `bootstrap.sh --apply --packages` installs the profile, so no manual `npm install -g` is needed for those CLIs. apk still owns the base system, init and services. See `docs/nix.md`.

### Individual Service Commands

Every project lives in its own file under `podman/`. Run one with
`podman-compose -f`, or bring the existing containers back with the boot script.
Set `COMPOSE_PROJECT_NAME` so the project name matches what `bootstrap.sh` used.

```bash
export COMPOSE_PROJECT_NAME="$USER"

# AdGuard Home
podman-compose -f podman/podman-adguard.yml up -d
podman-compose -f podman/podman-adguard.yml logs -f

# Vaultwarden
podman-compose -f podman/podman-vaultwarden.yml up -d

# Nginx Proxy Manager (reverse proxy)
podman-compose -f podman/podman-npm.yml up -d

# homelab-fetch (needs HOMELAB_API_URL / HOMELAB_TRACKER_TOKEN in .env)
podman-compose -f podman/podman-fetch.yml up -d --build

# Nextcloud (needs MYSQL_* / NEXTCLOUD_* vars in .env)
podman-compose -f podman/podman-nextcloud.yml up -d

# Wordcraft (paths assume $HOME)
podman-compose -f podman/podman-wordcraft.yml up -d

# DVWA lab, reachable only from the host
podman-compose -f podman/podman-dvwa.yml up -d

# kanaos dashboard on port 3008
podman-compose -f podman/podman-kanaos.yml up -d

# Start the containers that already exist, same as boot
sudo ./scripts/podman-boot.sh

# Image refresh (weekly, Podman auto-update)
sudo $HOME/homelab/scripts/podman-auto-update.sh

```

---

## Automation

Automation notes live in `docs/`, one file per topic:

- [Automation overview](docs/automation.md), weekly image refresh, Podman boot recovery, and links to the rest.
- [Bot](docs/bot.md), Renovate dependency updates.
- [Issues](docs/issues.md), known behavior that looks like a bug and where to check real failures.
- [Auto commit](docs/auto-commit.md), the Hermes GitOps cron and the Paseo repo monitor.

---

## Secrets Management

**Never commit secrets to this repo!**

The AI GitOps cron uses the Git credentials already configured on `takamatsu`. No custom secret is required.

Template files (`.env.example`) show required variables for local deployment.

---

## Acknowledgments

- [walkxcode/dashboard-icons](https://github.com/walkxcode/dashboard-icons) for service icons
- [Renovate](https://github.com/renovatebot/renovate) for automated dependency updates
- [renovate[bot]](https://github.com/apps/renovate) for automated dependency updates
- The self-hosted community for inspiration

---

*Purely a hobby. Not production. Just fun.*

---

