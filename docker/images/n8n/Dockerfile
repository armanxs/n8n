# ========= Versions =========
ARG NODE_VERSION=22
ARG N8N_VERSION=1.112.4
ARG LAUNCHER_VERSION=1.3.1
ARG TARGETPLATFORM

# ===== Stage 1: Base with Node + deps =====
FROM n8nio/base:${NODE_VERSION} AS base
WORKDIR /home/node

# ===== Stage 2: Fetch n8n package for pinned version =====
FROM alpine:3.22.0 AS app
ARG N8N_VERSION
RUN set -e; \
    apk add --no-cache wget tar; \
    mkdir -p /app && cd /app; \
    wget -q "https://registry.npmjs.org/n8n/-/n8n-${N8N_VERSION}.tgz" -O n8n.tgz; \
    tar -xzf n8n.tgz; \
    mv package/* .; \
    rm -rf package n8n.tgz

# ===== Stage 3: (optional) task runner launcher =====
FROM alpine:3.22.0 AS launcher
ARG TARGETPLATFORM
ARG LAUNCHER_VERSION
RUN set -e; \
    case "$TARGETPLATFORM" in \
      "linux/amd64") ARCH_NAME="amd64" ;; \
      "linux/arm64") ARCH_NAME="arm64" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac; \
    mkdir /launcher-temp && cd /launcher-temp; \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz"; \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256"; \
    echo "$(cat task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256) task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz" > checksum.sha256; \
    sha256sum -c checksum.sha256; \
    mkdir -p /launcher-bin; \
    tar xzf task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz -C /launcher-bin; \
    cd / && rm -rf /launcher-temp

# ===== Stage 4: Final runtime image =====
FROM base AS runtime

ARG N8N_VERSION
ENV NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    SHELL=/bin/sh

# put n8n in place and symlink the bin
COPY --from=app /app /usr/local/lib/node_modules/n8n
RUN set -e; \
    cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 --build-from-source && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node

# optional: task runner launcher binaries
COPY --from=launcher /launcher-bin/* /usr/local/bin/

# NOTE: we DO NOT use an entrypoint script anymore.
# We start n8n explicitly on Railway’s assigned $PORT and 0.0.0.0.
EXPOSE 5678/tcp
USER node
CMD ["/bin/sh", "-lc", "echo \"Starting n8n on 0.0.0.0:${PORT:-5678}\"; n8n start --port ${PORT:-5678} --host 0.0.0.0"]
