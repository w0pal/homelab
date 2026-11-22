# Custom OpenRC services

These are the hand-written `/etc/init.d` services on `takamatsu`. Package-owned
scripts are not copied here. The four active custom services are also in the
`default` runlevel.

| Service | Source | Purpose |
|---|---|---|
| `9router` | `9router.openrc` | Local LLM router on port 20128 |
| `hermes-gateway` | `hermes-gateway.openrc` | Hermes messaging gateway, default profile |
| `paseo` | `paseo.openrc` | Paseo daemon, local agent control plane |
| `portfolio-api` | `portfolio-api.openrc` | Portfolio dev API behind the `homelab-status` funnel |

`hermes-gateway.bak.20261118083758` in `/etc/init.d` is a one-off backup of an
older `hermes-gateway` file. It is not active and is intentionally not stored
here.

All four services run as `tomori:tomori` under `supervise-daemon`. Restore one
with root access:

```sh
sudo install -m 0755 /home/tomori/homelab/init/<name>.openrc /etc/init.d/<name>
sudo rc-update add <name> default
sudo rc-service <name> restart
```

`portfolio-api.openrc` also re-adds the Tailscale funnel path
`/homelab-status` on start if it is missing.

Do not store secrets in these files. Values that must stay private belong in
`.env` files or the secret store.
