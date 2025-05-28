rebuild release_version:
    docker build \
        --build-arg TAILWINDCSS_VERSION=v{{release_version}} \
        -t ghcr.io/scriptogre/tailwindcss:{{release_version}} \
        -t ghcr.io/scriptogre/tailwindcss:latest \
        .

push release_version:
    docker push ghcr.io/scriptogre/tailwindcss:{{release_version}}
    docker push ghcr.io/scriptogre/tailwindcss:latest