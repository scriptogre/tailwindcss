# TailwindCSS Docker Image

A minimal Docker image for the Tailwind CSS standalone CLI that bundles `tini` for proper signal forwarding.

## Usage Example

Pull and run the image:

```bash
docker run \
  --init \
  --rm \
  --volume "$(pwd)":/code \
  ghcr.io/scriptogre/tailwindcss:latest \
    -i ./static/css/input.css \
    -o ./static/css/output.css \
    --watch=always
```

Or with Docker Compose:

```yaml
services:
   tailwindcss:
      image: ghcr.io/scriptogre/tailwindcss:latest
      volumes:
         - .:/code
      command: [
         "-i", "./static/css/input.css",
         "-o", "./static/css/output.css",
         "--watch=always"
      ]
      init: true
```

## Notes

- The final image is based on `debian:bullseye-slim` and includes the `tailwindcss` CLI.
- The container expects a bind mount from the host to `/code`, where your Tailwind CSS files are located.
- Use `init: true` in docker-compose for proper signal handling.