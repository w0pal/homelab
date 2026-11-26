# Wordcraft

`wordcraft-web` and `wordcraft-files` run under Podman on `takamatsu` (ports
8090 and 8091). Start them from the repo root:

```sh
podman-compose -f podman/podman-wordcraft.yml up -d
```

Static assets and `server.mjs` live under `/home/tomori/Projects/wordcraft-web`.
