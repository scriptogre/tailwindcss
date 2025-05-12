# ─── Stage 1: Download Tailwind CLI ─────────────────────────
FROM curlimages/curl:latest AS downloader

ARG TAILWIND_VERSION=4.1.5
ARG TARGETPLATFORM
ARG TARGETVARIANT

# Download TailwindCSS standalone CLI
RUN set -eux; \
    platform="$TARGETPLATFORM"; \
    OS="${platform%/*}"; \
    ARCH="${platform#*/}"; \
    [ "$ARCH" = "amd64" ] && ARCH=x64; \
    [ "$ARCH" = "aarch64" ] && ARCH=arm64; \
    url="https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWIND_VERSION}/tailwindcss-${OS}-${ARCH}${TARGETVARIANT}"; \
    curl -fSL -o /tmp/tailwindcss "$url"; \
    chmod +x /tmp/tailwindcss


# ─── Stage 2: Final Image ───────────────────────────────────────────────
FROM debian:bullseye-slim

ARG TAILWIND_VERSION=4.1.5

# Image metadata
LABEL org.opencontainers.image.title="Tailwind CSS CLI Docker Image"
LABEL org.opencontainers.image.description="Minimal Docker image packaging the Tailwind CSS standalone CLI"
LABEL org.opencontainers.image.documentation="https://github.com/scriptogre/tailwindcss-docker#readme"
LABEL org.opencontainers.image.source="https://github.com/scriptogre/tailwindcss-docker"
LABEL org.opencontainers.image.url="https://github.com/scriptogre/tailwindcss"
LABEL org.opencontainers.image.version="${TAILWIND_VERSION}"
LABEL org.opencontainers.image.authors="scriptogre"

# Copy Tailwind CLI from `downloader` stage
COPY --from=downloader /tmp/tailwindcss    /usr/local/bin/tailwindcss

# Set /code as work dir (this is where user's files should be mounted)
WORKDIR /code

ENTRYPOINT ["/usr/local/bin/tailwindcss"]

# Default to TailwindCSS CLI's help message
CMD ["--help"]
