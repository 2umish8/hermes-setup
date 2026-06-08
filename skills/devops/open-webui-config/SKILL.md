---
name: open-webui-config
category: devops
description: "Configure Open WebUI environment variables, handle model discovery and troubleshooting for OpenAI/Ollama integrations."
tags:
  - open-webui
  - ollama
  - openai
  - env
  - config
trigger: |
  User asks to:
    - configure / troubleshoot Open WebUI environment vars
    - ensure models are detected
    - set correct base URLs and keys
    - enable or disable Ollama or OpenAI integration
---

# Open WebUI Configuration & Model Discovery

## Overview
Open WebUI is a simple Python web app that exposes a CLI to OpenAI-compatible APIs. It uses the following env vars:

| Variable | Description | Typical Value | Notes |
|----------|-------------|--------------|-------|
| `ENABLE_OLLAMA_API` | Set `true` to allow the OLlama integration | `true` or `false` | Must be a string literal (no quotes inside config files) |
| `OLLAMA_BASE_URLS` | URL(s) where Ollama API listens (comma separated) | `http://127.0.0.1:8642` | Include protocol & port; omit trailing slash |
| `OPENAI_API_BASE_URL` | Base URL for OpenAI-compatible API | `http://host.docker.internal:8642/v1` | Use DNS name or IP; proto must be `http` if not HTTPS |
| `OPENAI_API_KEY` | API key for the OpenAI-compatible endpoint | `my-key-2026` | Hide in vault / secret manager |
| `PORT` | Internal port Open WebUI should expose | `3001` | Only required when `network_mode: host`; use default if publishing 3000:8080 |

By default, Open WebUI falls back to Ollama if `ENABLE_OLLAMA_API=true`. Without a correctly running Ollama, it will report *"Error: Ollama API not available"* and model discovery will fail.

## Common Troubleshooting Steps
1. **Verify the service is running** – `docker compose ps` or `sudo docker ps -a`.
2. **Check port bindings** – `sudo ss -tlnp | grep :8642` ensures the encoder is listening on the expected port.
3. **Validate environment vars** – run `docker inspect open-webui` and grep for `ENV` or just `docker compose exec open-webui env`.
4. **Look at logs** – `docker logs open-webui | tail -n 50`. Look for `Connection error: Cannot connect to host host.docker.internal:8642` which indicates the URL is wrong inside the container.
5. **Restart the container** – after any env change, run
   ```bash
   docker compose down && docker compose up -d --force-recreate
   ```
6. **Check health endpoint** – `curl -s https://open-webui.dev.mowtif.com/api/health?refresh=true` should return a 200 JSON payload.
7. **Confirm model list endpoint** – `curl -s https://open-webui.dev.mowtif.com/api/models?refresh=true` (or use `http://127.0.0.1:8642/v1/models` when hitting the container directly) should list the available models.

## Common Pitfalls
- **Mismatched environment variable values** – e.g., using `localhost` inside the container. The container's network namespace does not resolve `localhost` to the host; use `host.docker.internal` (for Docker Desktop) or the container IP of the host.
- **Wrong port in `OLLAMA_BASE_URLS`** – hence the `Cannot connect to host host.docker.internal:8642` error. The port must match the Ollama container's exposed port.
- **Lack of `OPENAI_API_KEY` while `ENABLE_OLLAMA_API=false`** – Causes a 401 error from OpenAI endpoint.
- **Overwritten env file in compose** – If you use `.env`, make sure the variables are defined and not overridden by service `environment` block.
- **Network mode** – In `network_mode: host`, the container shares the host network stack; `localhost` refers to the host itself. In bridge mode, you must map ports explicitly.

## Suggested Setup Script
Place this script in `~/.hermes/scripts/launch-openwebui.sh`:
```bash
#!/usr/bin/env bash
set -eu
# Launch Open WebUI with correct env vars
compose_file=/home/hermes/open-webui-compose.yaml
# Ensure env vars are in place
cat >$compose_file <<EOF
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: always
    ports:
      - "3000:8080"
    environment:
      - ENABLE_OLLAMA_API=true
      - OLLAMA_BASE_URLS=http://127.0.0.1:8642
      - OPENAI_API_BASE_URL=http://host.docker.internal:8642/v1
      - OPENAI_API_KEY=***
      - PORT=3001
    extra_hosts:
      - "host.docker.internal:host-gateway"
    network_mode: "host"
EOF
chmod +x $compose_file
sudo docker compose -f $compose_file down
sudo docker compose -f $compose_file up -d --force-recreate
EOF
```

Run it with: `bash ~/hermes/scripts/launch-openwebui.sh`.

---

## References
- `references/openwebui-env.md` – Full env var matrix and typical values.
- `references/ollama-runtime.md` – How to run Ollama locally and expose correct port.
- `references/ollama-to-openai.md` – Why Open WebUI uses Ollama as fallback.

---

## Version
v1.0.0 – initial creation.
