# Hermes Agent Integration with Open WebUI

This reference documents the integration of Hermes Agent with Open WebUI, allowing you to use Open WebUI's interface while maintaining full Hermes Agent tool execution capabilities.

## Architecture

- **Runtime:** Hermes acts as the backend API server.
- **Tools:** Tools execute on the host machine running Hermes.
- **Communication:** SSE streaming is supported for real-time tool progress (e.g., showing `💻 ls -la` in the chat).

## Setup Recipe

1. **Enable Hermes API Server:**
   ```bash
   hermes config set API_SERVER_ENABLED true
   hermes config set API_SERVER_KEY "your-secure-key"
   hermes gateway stop
   hermes gateway &
   ```

2. **Open WebUI (Docker Compose):**
   ```yaml
   services:
     open-webui:
       image: ghcr.io/open-webui/open-webui:main
       container_name: open-webui
       restart: always
       ports:
         - "3000:8080"
       environment:
         - OPENAI_API_BASE_URL=http://host.docker.internal:8642/v1
         - OPENAI_API_KEY=your-secure-key
         - ENABLE_OLLAMA_API=false
       extra_hosts:
         - "host.docker.internal:host-gateway"
   ```

## Troubleshooting

- **Connection Failure:** Ensure `http://host.docker.internal:8642/v1` is reachable from inside the Open WebUI container. If using `--network=host`, use `localhost` instead of `host.docker.internal`.
- **API Key issues:** Ensure the `OPENAI_API_KEY` in the container environment matches the `API_SERVER_KEY` set in Hermes.
- **Service Restart:** Open WebUI saves configuration internally after first launch. If variables change, update connection settings via the Admin UI or delete the Docker volume to force a re-configuration.
