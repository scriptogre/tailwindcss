# TailwindCSS Docker

A dead simple way to run [Tailwind CSS](https://tailwindcss.com/) from a Docker container. 

No more **Node.JS**. No more **manual downloads of the CLI**.

1. Create `input.css` in your project:
    ```css
    @import 'tailwindcss';
    ``` 
2. Create `docker-compose.yml` in your project:
    ```yaml
    services:
      tailwindcss:
        # You can also use pinned versions, e.g. `:4.1.7`
        image: ghcr.io/scriptogre/tailwindcss:latest
        volumes:
          - .:/app
        command: -i ./input.css -o ./output.css --watch
    ```

3.  Or run `docker run` command:
```bash
docker run \ 
  -v "$(pwd)":/app \
  ghcr.io/scriptogre/tailwindcss:latest \ 
  -i ./input.css -o ./output.css --watch
```


### **Notes:**
- Make sure you mount all source files (`*.html`, `*.css`, `*.js`, …) to `/app`, so Tailwind’s watcher can see them within the container.
- The `ghcr.io/scriptogre/tailwindcss:latest` image is rebuilt daily to track the newest Tailwind CSS release.