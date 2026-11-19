# nginx-proxy-manager

Admin UI: `http://192.168.0.240:81`. Running deployment: `~/containers/nginx-proxy-manager`
(this repo dir holds the reference compose; the live data/letsencrypt volumes are under `~/containers`).

## Proxy host 7 — Vaultwarden on the tailnet hostname (LAN access)

- `takamatsu.tailb43e01.ts.net` → `http://192.168.0.240:8080` (vaultwarden), Force SSL + Websockets Support enabled.
- LAN clients resolve the hostname via the **AdGuard Home rewrite**
  `takamatsu.tailb43e01.ts.net → 192.168.0.240`, so they hit this vhost directly —
  no Tailscale needed on the LAN. (Devices using Private DNS/DoH bypass AdGuard and won't get the rewrite.)
- TLS: custom cert `npm-3` in the NPM UI = real Let's Encrypt cert issued by
  `tailscale cert takamatsu.tailb43e01.ts.net`. Files: `/data/custom_ssl/npm-3/{fullchain.pem,privkey.pem}`.
  Do NOT replace it with a `*.lab` or `lab.tailb43e01.ts.net` cert — hostname mismatch breaks Bitwarden clients.
- Renewal: `~/homelab/scripts/renew-takamatsu-cert.sh`, weekly user cron (Mon 04:17),
  renews when <30 days validity remain, reloads nginx only on change.
  Log: `~/.local/log/takamatsu-cert.log`. Old cert backed up as `*.bak-lab-cert` in the same dir.

## How the hostname is routed elsewhere (tailscale serve/funnel on takamatsu)

- `:443` — **Funnel (public)**, only `/9router` → `127.0.0.1:20128` (9router LLM router UI/API). Root `/` is 404.
- `:8443` — tailnet-only serve, `/` → vaultwarden. This is the URL Vaultwarden's `DOMAIN` currently advertises.
- `:8080` — tailnet-only → router (`192.168.0.1:80`); `:8181` — tailnet-only → NPM UI.
- Funnel is per-port (`AllowFunnel` keyed by host:port): any handler added to funneled `:443`
  becomes public. Vaultwarden cannot share `:443` with `/9router` privately.
