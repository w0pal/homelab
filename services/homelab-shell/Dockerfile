FROM alpine:3.22

RUN apk add --no-cache python3 py3-pip btop fastfetch util-linux tzdata \
    && pip install --break-system-packages --no-cache-dir pyte

WORKDIR /app
COPY worker.py fastfetch.jsonc ./

ENV HOME=/tmp TERM=xterm-256color TZ=Asia/Jakarta LANG=C.UTF-8 LC_ALL=C.UTF-8

USER nobody
CMD ["python3", "worker.py"]
