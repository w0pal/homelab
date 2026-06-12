# My Homelab

This repository contains the GitOps configuration for my personal homeserver.
This is purely a **hobby project** — it runs services for fun and personal
convenience (media, passwords, network tools), not for development, production,
or anything serious. I tinker with it in my free time.

I don't aim for perfection here (seriously). Things will change often as I experiment and
figure out better ways to manage this. This repo works both as
documentation for myself and as something others can look at to learn from. If you
find something useful, feel free to use it in your own projects.

The setup includes a mix of media services, personal productivity tools, and
infrastructure components. Some are for fun, some are for convenience, and
others are just experiments. Nothing here is production-grade — it's just my
weekend project.

Feel free to explore and see how everything is set up. If you have any
questions or suggestions, you can reach out to me on GitHub (w0pal). If I can help you with something, I
will be happy to do so.

---

# Installed Apps

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
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/caddy.svg" width="32" /></td>
        <td>Caddy</td>
        <td>Reverse proxy with automatic HTTPS (using Tailscale certs) for LAN access to services</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/portainer.svg" width="32" /></td>
        <td>Portainer</td>
        <td>Docker container management UI for easy service administration</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/watchtower.svg" width="32" /></td>
        <td>Watchtower</td>
        <td>Automated container updates on a schedule (daily at 2 AM)</td>
    </tr>
    <tr>
        <td><img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/cockpit.svg" width="32" /></td>
        <td>Cockpit</td>
        <td>Web-based server management console (system package, port 9090)</td>
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

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet / Tailscale                      │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTPS (443)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Caddy (Reverse Proxy)                   │
│  • TLS termination (Tailscale certs for lab.tailf2af36.ts.net)│
│  • Routes to Vaultwarden on 127.0.0.1:8080                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────┐     ┌───────────────────────┐
│    Vaultwarden        │     │   AdGuard Home        │
│    (Port 8080)        │     │   (Port 53/3000)      │
└───────────────────────┘     └───────────────────────┘
              │                           │
              ▼                           ▼
     ┌─────────────────┐         ┌─────────────────┐
     │  vw-data volume │         │  DNS rewrites:  │
     │  (persistent)   │         │  • vault.local  │
     └─────────────────┘         │  • lab.tail...  │
                                 │  • router.test  │
                                 └─────────────────┘
```

## Service Details

| Service | Port(s) | Network | Health Check |
|---------|---------|---------|--------------|
| AdGuard Home | 53 (DNS), 3000 (Web) | `lsio` (host) | Built-in |
| Caddy | 80, 443 | `shared-web` | Auto |
| Vaultwarden | 8080 (internal) | `shared-web` | `/alive` endpoint |
| Portainer | 9000 | `portainer_default` | Auto |
| Watchtower | 8080 (API) | `watchtower_default` | Auto |
| Cockpit | 9090 | Host (systemd) | Built-in |

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
cd ../caddy && docker compose up -d
cd ../vaultwarden && docker compose up -d
cd ../portainer && docker compose up -d
cd ../watchtower && docker compose up -d

# Cockpit runs as a system package (not Docker)
# sudo systemctl enable --now cockpit.socket
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

# Caddy (reverse proxy)
cd services/caddy
docker compose up -d

# Watchtower (auto-updates)
cd services/watchtower
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
│   ├── caddy/
│   │   ├── docker-compose.yml
│   │   └── Caddyfile                     # Reverse proxy config
│   ├── cockpit/
│   │   └── docker-compose.yml            # Docker alternative (system package preferred)
│   ├── vaultwarden/
│   │   ├── docker-compose.yml
│   │   └── .env.example                  # Template for secrets
│   ├── portainer/
│   │   └── docker-compose.yml
│   └── watchtower/
│       └── docker-compose.yml
├── .github/
│   └── workflows/
│       ├── renovate.yml              # Auto dependency updates
│       └── sync-config.yml           # Auto-commit config changes
├── scripts/
│   └── sync-from-server.sh           # Pull configs from running server
├── renovate.json                     # Renovate bot configuration
├── .gitignore
└── README.md
```

---

## Automation

### Renovate Bot (Auto Dependency Updates)

This repo uses [Renovate](https://github.com/renovatebot/renovate) to automatically create PRs for:

- Docker base image updates (`caddy:latest`, `vaultwarden/server:latest`, etc.)
- Docker Compose version updates
- GitHub Actions updates

Renovate runs on a schedule and groups related updates. Check `renovate.json` for configuration.

### Config Sync (Auto-commit Server Changes)

The `sync-config.yml` workflow can be triggered to pull configuration from the running homeserver and commit changes. This captures:

- AdGuard Home YAML config changes
- Caddyfile modifications
- Docker Compose file updates

Run manually from Actions tab or set up a cron schedule.

---

## Secrets Management

**Never commit secrets to this repo!**

The only secret used by GitHub Actions is:

| Secret | Where to Set |
|--------|--------------|
| `HOMESERVER_SSH_KEY` | GitHub Repository Settings → Secrets → Actions |

This allows the auto-sync workflow to SSH into the homeserver and pull config changes.

Template files (`.env.example`) show required variables for local deployment.

---

## Hardware

Device specs:

- **ZTE B860H** (this homeserver)
  ```
  OS: Armbian 26.5.1 trixie aarch64
  Kernel: Linux 6.12.91-ophub
  SoC: Amlogic p212 (4 cores @ 1.51 GHz)
  GPU: Amlogic meson-gxl-mali [Integrated]
  RAM: 1.75 GiB
  Storage: 58.24 GiB (SD) + 6.47 GiB (eMMC)
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

*Last updated: $(date +%Y-%m-%d)*