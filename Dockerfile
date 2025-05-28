# ─── Stage 1: Download TailwindCSS CLI ─────────────────────────
FROM curlimages/curl:latest AS downloader

ARG TAILWINDCSS_VERSION
ARG TARGETPLATFORM
ARG TARGETVARIANT

# Download TailwindCSS CLI
RUN set -eux; \
    platform="$TARGETPLATFORM"; \
    OS="${platform%/*}"; \
    ARCH="${platform#*/}"; \
    [ "$ARCH" = "amd64" ] && ARCH=x64; \
    [ "$ARCH" = "aarch64" ] && ARCH=arm64; \
    url="https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWINDCSS_VERSION}/tailwindcss-${OS}-${ARCH}${TARGETVARIANT}"; \
    curl -fSL -o /tmp/tailwindcss "$url"; \
    chmod +x /tmp/tailwindcss


# ─── Stage 2: Final Image ───────────────────────────────────────────────
FROM debian:bullseye-slim

ARG TAILWINDCSS_VERSION

# Image metadata
LABEL org.opencontainers.image.title="Tailwind CSS CLI Docker Image"
LABEL org.opencontainers.image.description="Minimal Docker image packaging the Tailwind CSS standalone CLI"
LABEL org.opencontainers.image.documentation="https://github.com/scriptogre/tailwindcss-docker#readme"
LABEL org.opencontainers.image.source="https://github.com/scriptogre/tailwindcss-docker"
LABEL org.opencontainers.image.url="https://github.com/scriptogre/tailwindcss"
LABEL org.opencontainers.image.version="${TAILWINDCSS_VERSION}"
LABEL org.opencontainers.image.authors="scriptogre"

# Install Watchman
RUN apt-get update && \
    apt-get install -y --no-install-recommends watchman && \
    rm -rf /var/lib/apt/lists/*

# Copy Tailwind CLI from `downloader`
COPY --from=downloader /tmp/tailwindcss    /usr/local/bin/tailwindcss

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/tailwindcss"]

# Ensures container doesn't hang on CTRL+C (alternative is setting `stop_grace_period: 0` in `docker-compose.yml`)
STOPSIGNAL SIGKILL

# Default to TailwindCSS CLI's help message
CMD ["--help"]
