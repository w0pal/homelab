# Wordcraft

`wordcraft-web` and `wordcraft-files` currently run via `docker run` on
`takamatsu` (ports 8090 and 8091). There is no compose file on the host; the
one here was reconstructed from `docker inspect` so the setup is documented.

Static assets and `server.mjs` live under `/home/tomori/Projects/wordcraft-web`.
