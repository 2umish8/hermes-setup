## Host‑internal usage in Docker Compose (Open WebUI)

When Docker runs in *host* network mode the `localhost` inside the container refers **to the host itself**. This is why an Open WebUI container can reach an Ollama server exposed on the host’s loopback interface via `host.docker.internal:8642` (Docker Desktop) or the host’s IP.

* What can go wrong:
  - Using `localhost` or `127.0.0.1` in the compose env variable will point to the *container* itself – not the host – causing a `Cannot connect to host localhost:8642` error.
  - On Linux Docker Engine the hostname `host.docker.internal` is not defined by default; you must add an `extra_hosts` mapping or use the actual host IP.

* Solutions in this repo:
  - In `/home/hermes/open-webui-compose.yaml` we add `extra_hosts:
    - "host.docker.internal:host-gateway"` so that the name resolves w/ the host’s gateway.
  - Then set `OPENAI_API_BASE_URL=http://host.docker.internal:8642/v1` and `OLLAMA_BASE_URLS=http://127.0.0.1:8642` (the Ollama container listens on 8642 on the host). The container will thus resolve the host name correctly.

Make sure the Docker Engine supports the `host-gateway` alias (most recent Docker Desktop and Docker Engine >20.10). Otherwise substitute with the actual IP of the host.
