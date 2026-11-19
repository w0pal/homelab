# homelab-fetch

Live fastfetch for the portfolio's **Now** page. A tiny isolated container
runs real [fastfetch](https://github.com/fastfetch-cli/fastfetch) against
read-only host mounts and pushes normalized stats to the portfolio tracker
API (`api/homelab.js` in `portfolio-web`). The Now page polls that API every
3 seconds and renders the output as a terminal window.

When the lab is powered off (or unreachable), pushes stop; after 90 seconds
without a push the API reports `online: false` and the page shows
**"the homelab is turned off."**

## How it reads host stats from a container

fastfetch normally reports the container's own environment. Mounting the
host's pseudo-filesystems read-only makes it report the host instead:

| Mount | What fastfetch reads from it |
|-------|------------------------------|
| `/proc:/proc:ro` | uptime, CPU, memory, swap, load |
| `/sys:/sys:ro` | DMI product name, CPU freq, GPU (i915) |
| `/etc/os-release:/etc/os-release:ro` | host distro |
| `/:/host:ro` | host disk usage (`disk.folders: "/host"` in `fastfetch.jsonc`) |

Hostname, user and LAN IP are read from `/host/etc/hostname`,
`/host/etc/passwd` and `/host/proc/1/net/{route,fib_trie}` (pid 1's net
directory, because `/proc/net` is network-namespace aware).

## Isolation

- runs as non-root (`node` user), `cap_drop: ALL`, `no-new-privileges`
- read-only container rootfs, all host mounts `:ro`
- no docker socket, no published ports, no host network — outbound HTTPS only
- 128 MB / 0.5 CPU limit

## Setup

```bash
cp .env.example .env
# edit .env:
#   HOMELAB_API_URL=https://<your-portfolio>/api/homelab
#   HOMELAB_TRACKER_TOKEN=<same token as HOMELAB_TRACKER_TOKEN on Vercel>
docker compose up -d --build
docker logs -f homelab-fetch
```

On the portfolio side (Vercel env vars): set `HOMELAB_TRACKER_TOKEN` to the
same value. Upstash Redis (`UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN`)
is reused from the Anki tracker; without it the API falls back to in-memory
storage (fine for local dev, not for serverless prod).

## Local dev

Point `HOMELAB_API_URL` at the dev API instead:

```
HOMELAB_API_URL=http://192.168.0.240:3001/api/homelab
```

(`node --env-file=.env scripts/dev-api.mjs` in portfolio-web serves
`/api/homelab` on port 3001, which `vite dev` proxies.)
