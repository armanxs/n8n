# ========= Versions =========
ARG NODE_VERSION=22
ARG N8N_VERSION=1.112.4
ARG LAUNCHER_VERSION=1.3.1
ARG TARGETPLATFORM

# ======================================================================
# STAGE 1: Base (Node + system deps from official n8n base)
# ======================================================================
FROM n8nio/base:${NODE_VERSION} AS system-deps

# ======================================================================
# STAGE 2: Fetch n8n package for the pinned version
# ======================================================================
FROM alpine:3.22.0 AS app-artifact-processor
ARG N8N_VERSION

RUN set -e; \
    apk add --no-cache wget tar; \
    mkdir -p /app && cd /app; \
    wget -q "https://registry.npmjs.org/n8n/-/n8n-${N8N_VERSION}.tgz" -O n8n.tgz; \
    tar -xzf n8n.tgz; \
    mv package/* .; \
    rm -rf package n8n.tgz

# ======================================================================
# STAGE 3: Download task-runner launcher (optional but supported)
# ======================================================================
FROM alpine:3.22.0 AS launcher-downloader
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

# ======================================================================
# STAGE 4: Final runtime image
# ======================================================================
FROM system-deps AS runtime

ARG N8N_VERSION
ARG N8N_RELEASE_TYPE=dev

ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
ENV SHELL=/bin/sh

WORKDIR /home/node

# n8n app + launcher + entrypoint/scripts
COPY --from=app-artifact-processor /app /usr/local/lib/node_modules/n8n
COPY --from=launcher-downloader /launcher-bin/* /usr/local/bin/
COPY docker/images/n8n/docker-entrypoint.sh /
COPY docker/images/n8n/n8n-task-runners.json /etc/n8n-task-runners.json

# Make entrypoint executable and finalize n8n bin
RUN set -e; \
    cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 --build-from-source && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node && \
    chmod +x /docker-entrypoint.sh

# Optional add-on: only install @napi-rs/canvas if pdfjs-dist exists
RUN if [ -d "/usr/local/lib/node_modules/n8n/node_modules/pdfjs-dist" ]; then \
      cd /usr/local/lib/node_modules/n8n/node_modules/pdfjs-dist && \
      npm install --omit=dev @napi-rs/canvas; \
    else \
      echo "pdfjs-dist not present in this n8n version; skipping canvas install"; \
    fi

EXPOSE 5678/tcp
USER node
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

LABEL org.opencontainers.image.title="n8n" \
      org.opencontainers.image.description="Workflow Automation Tool" \
      org.opencontainers.image.source="https://github.com/n8n-io/n8n" \
      org.opencontainers.image.url="https://n8n.io" \
      org.opencontainers.image.version=${N8N_VERSION}
