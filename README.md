# My Homelab

This repository contains the GitOps configuration for my personal homeserver.
This is purely a **hobby project**. It runs services for fun and personal
convenience (media, passwords, network tools), not for development, production,
or anything serious. I tinker with it in my free time.

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

The tables below are the original catalogue and still include a few experiments that are no longer running. For what is live right now on `takamatsu`, see [Current runtime](#current-runtime).

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
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/dockge.svg" width="32" /></td>
        <td>Dockge</td>
        <td>Docker container management UI for easy service administration</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/watchtower.svg" width="32" /></td>
        <td>Watchtower</td>
        <td>Automated container updates on a schedule (Monthly at 2 AM)</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/cockpit.svg" width="32" /></td>
        <td>Cockpit</td>
        <td>Web-based server management console (Docker container, port 9090)</td>
    </tr>
</table>

<h2>📊 Monitoring</h2>
<table>
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/uptime-kuma.svg" width="32" /></td>
        <td>Uptime Kuma</td>
        <td>Uptime monitoring and status page for all services</td>
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
        <td>homelab-fetch</td>
        <td>Read-only fastfetch reporter used by the Hermes bot</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/terminal.svg" width="32" /></td>
        <td>homelab-shell</td>
        <td>Read-only shell worker that polls the portfolio API for jobs</td>
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
</table>

## Current runtime

Snapshot taken 2026-11-22 from `takamatsu` (Alpine 3.24, x86_64).

**Docker Compose projects running:** `adguardhome`, `homelab-fetch`,
`homelab-shell`, `nginx-proxy-manager`, `nextcloud` (4 containers),
`vaultwarden`, `watchtower`. Wordcraft's two containers run from `docker run`,
not Compose.

**OpenRC services enabled:** `9router`, `containerd`, `crond`, `dnsmasq`,
`docker`, `hermes-gateway`, `local`, `ntpd`, `paseo`, `portfolio-api`, `redis`,
`sshd`, `tailscale`.

**Configs kept but not currently running:** Dockge, Cockpit, Uptime Kuma,
opencode-bot, hermes-agent containers.

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet / Tailscale                      │
└───────────────────────────┬─────────────────────────────────┘
             │ HTTP (80) / HTTPS (443)
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│              Nginx Proxy Manager (Reverse Proxy)                  │
│  • Web UI for managing proxy hosts (port 81)                      │
│  • Routes to Vaultwarden, Dockge, Cockpit, Uptime Kuma            │
└──────┬─────────────┬──────────────┬──────────────────┬───────────┘
       │             │              │                  │
       ▼             ▼              ▼                  ▼
┌──────────┐  ┌──────────┐  ┌──────────┐       ┌──────────┐
│Vaultwarden│  │  Dockge  │  │ Cockpit  │       │Uptime    │
│(internal) │  │ container│  │ container│       │  Kuma    │
│:80        │  │ :5001    │  │ :9090    │       │ :3001    │
└──────────┘  └──────────┘  └──────────┘       └──────────┘
```

The diagram is historical; Nextcloud (`nextcloud.lab`) is also proxied through NPM.

## Service Details

| Service | Port(s) | Network | Health Check |
|---------|---------|---------|--------------|
| AdGuard Home | 53 (DNS), 3000 (Web) | `lsio` (host) | Built-in |
| Nginx Proxy Manager | 80, 443, 81 (Admin) | `shared-web` | Auto |
| Vaultwarden | 8080 (internal) | `shared-web` | `/alive` endpoint |
| Dockge | 5001 | `shared-web` | Auto |
| Watchtower | N/A | `watchtower_default` | Auto |
| Cockpit | 9090 | `shared-web` | Built-in |
| Uptime Kuma | 3001 | Host | Built-in |
| Nextcloud | 80 (via NPM) | `backend`, `shared-web` | MariaDB healthcheck |
| Wordcraft | 8090, 8091 | bridge | — |
| homelab-fetch | none (outbound only) | none | — |
| homelab-shell | none (outbound only) | none | — |

---

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Tailscale (for remote HTTPS)
- A domain or Tailscale MagicDNS name

### Deploy All Services

```bash
# Clone this repo
git clone https://github.com/w0pal/homelab.git
cd homelab

# Create the shared network (run once)
docker network create shared-web

# Deploy each service
cd services/adguardhome && docker compose up -d
cd ../nginx-proxy-manager && docker compose up -d
cd ../vaultwarden && docker compose up -d
cd ../dockge && docker compose up -d
cd ../cockpit && docker compose up -d
cd ../watchtower && docker compose up -d
cd ../nextcloud && docker compose up -d
cd ../wordcraft && docker compose up -d
```

### Individual Service Commands

```bash
# AdGuard Home
cd services/adguardhome
docker compose up -d          # Start
docker compose logs -f        # View logs
docker compose down           # Stop

# Vaultwarden
cd services/vaultwarden
docker compose up -d

# Nginx Proxy Manager (reverse proxy)
cd services/nginx-proxy-manager
docker compose up -d

# Dockge (container manager)
cd services/dockge
docker compose up -d

# Cockpit (web server management)
cd services/cockpit
docker compose up -d

# Watchtower (auto-updates)
cd services/watchtower
docker compose up -d

# Nextcloud (needs MYSQL_* / NEXTCLOUD_* vars in .env)
cd services/nextcloud
docker compose up -d

# Wordcraft (paths assume /home/tomori)
cd services/wordcraft
docker compose up -d

# Uptime Kuma (monitoring)
cd services/uptime-kuma
docker compose up -d
```

---

## Configuration Files

```
homelab/
├── services/
│   ├── adguardhome/
│   │   ├── docker-compose.yml
│   │   └── AdGuardHome.yaml              # Main config (sync from running container)
│   ├── nginx-proxy-manager/
│   │   └── docker-compose.yml            # Reverse proxy with web UI
│   ├── cockpit/
│   │   └── docker-compose.yml            # Web server management (Docker container)
│   ├── vaultwarden/
│   │   ├── docker-compose.yml
│   │   └── .env.example                  # Template for secrets
│   ├── dockge/
│   │   └── docker-compose.yml
│   ├── uptime-kuma/
│   │   └── docker-compose.yml            # Uptime monitoring
│   ├── watchtower/
│   │   └── docker-compose.yml
│   ├── nextcloud/
│   │   └── docker-compose.yml            # db, redis, app, storage watcher
│   ├── wordcraft/
│   │   ├── docker-compose.yml            # reconstructed from running containers
│   │   └── README.md
│   ├── homelab-fetch/
│   │   └── docker-compose.yml
│   ├── homelab-shell/
│   │   └── docker-compose.yml
│   ├── opencode-bot/
│   │   └── docker-compose.yml
│   └── hermes-agent/
│       └── docker-compose.yml
├── .github/
│   └── workflows/
│       ├── renovate.yml              # Dependency updates
│       └── auto-commit-config.yml    # Manual config sync
├── init/
│   ├── 9router.openrc
│   ├── hermes-gateway.openrc
│   ├── paseo.openrc
│   ├── portfolio-api.openrc
│   └── README.md
├── scripts/
│   ├── sync-homelab.sh               # Snapshot live host config
│   ├── auto-commit-homelab.sh        # Legacy sync helper
│   ├── ensure-portfolio-api.sh       # Watchdog fallback
│   ├── install-portfolio-api-service.sh
│   └── renew-takamatsu-cert.sh
├── renovate.json                     # Renovate bot configuration
├── .gitignore
└── README.md
```

---

## Automation

### Renovate Bot (Auto Dependency Updates)

This repo uses [Renovate](https://github.com/renovatebot/renovate) to automatically create PRs for:

- Docker base image updates (`jc21/nginx-proxy-manager:latest`, `vaultwarden/server:latest`, etc.)
- Docker Compose version updates
- GitHub Actions updates

Renovate runs on a schedule and groups related updates. Check `renovate.json` for configuration.

### AI GitOps sync

A Hermes cron job watches the host every five minutes. It runs `scripts/sync-homelab.sh`, reviews the diff, and groups changes by feature. Each feature gets its own Conventional Commit with a short body that names the files and explains the change. The job pushes to `main` once after all commits.

The job uses the `git-conventional-push` and `w0pal-writing-style` skills. It never commits secrets or real `.env` files. It skips runs when nothing changed.

The old five-minute `auto-commit-homelab.sh` cron entry is retired. The GitHub Actions workflow is now manual only. Use it from the Actions tab when you want a one-off pull from the host.

---

## Secrets Management

**Never commit secrets to this repo!**

The GitHub Actions run uses the built-in `GITHUB_TOKEN`. The AI GitOps cron uses the Git credentials already configured on `takamatsu`. No custom secret is required for either path.

Template files (`.env.example`) show required variables for local deployment.

---

## Hardware

- **HP EliteDesk 800 G3 DM 35W** (homelab host, `takamatsu`)
  ```
  OS: Alpine Linux v3.24 x86_64
  Kernel: Linux 6.18.63-0-lts
  CPU: Intel Core i5-7500T (4 cores @ 3.30 GHz)
  GPU: Intel HD Graphics 630 @ 1.10 GHz
  RAM: 8 GiB DDR4
  Storage: 229 GiB ext4
  ```

The old ZTE B860H set-top box is retired.

- **OpenWrt** (router @ 192.168.0.1)
  ```
  OS: OpenWrt
  Role: Gateway, DHCP, NAT
  Network: 192.168.0.0/24 LAN
  ```

---

## Acknowledgments

- [walkxcode/dashboard-icons](https://github.com/walkxcode/dashboard-icons) for service icons
- [Renovate](https://github.com/renovatebot/renovate) for automated dependency updates
- [renovate[bot]](https://github.com/apps/renovate) for automated dependency updates
- The self-hosted community for inspiration

---

*Purely a hobby. Not production. Just fun.*

---

*Last updated: 2026-06-18*
