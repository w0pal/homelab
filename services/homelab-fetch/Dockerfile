FROM node:26-alpine

RUN apk add --no-cache fastfetch

WORKDIR /app
COPY collector.mjs fastfetch.jsonc ./

USER node
CMD ["node", "collector.mjs"]
