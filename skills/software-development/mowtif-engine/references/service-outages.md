# Troubleshooting Service Outages

If an application in the monorepo is unreachable:
1. **Check process:** `sudo ss -tlnp` to check if the port is listening.
2. **Check logs:** Verify the app's log file (e.g., `~/app-name.log`).
3. **Recovery:** If the process is down, verify if it was managed by systemd. If not, standard procedure is to create a systemd service unit in `/etc/systemd/system/` to ensure persistence.
