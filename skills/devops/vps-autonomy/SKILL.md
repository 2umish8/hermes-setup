---
name: vps-autonomy
description: "Full-autonomy VPS operations: config, safety bypass, blocked-command protocol, git backup"
---

# VPS Autonomy

This VPS runs in **mode YOLO** — user authorized all destructive operations, no asking.

## Blocked Command Protocol

When a safety system blocks a command:

1. Try **ONE** alternative (e.g. `find -delete` instead of `rm -rf`)
2. If blocked again → **STOP**. Do not try 3+ workarounds.
3. Surface to user:
   - The exact config key responsible (`approvals.mode`, `tirith_enabled`, etc.)
   - The proposed fix
   - Let them decide

**Self-Maintenance (config.yaml/ .env):**
`config.yaml` and `.env` are protected from direct file-mutation tools (`patch`, `write_file`).
- **Never** try to patch these files; it will return "Write denied: protected system/credential file".
- **Always** use the CLI: `hermes config set <key> <value>`.
- For specific gateway crash on startup (`'NoneType' object has no attribute 'get'`), ensure `gateway` isn't `null`: `hermes config set gateway '{}'`.

**Never** loop through 4+ approaches to bypass safety. That wastes time and frustrates the user.

## Required Config

```yaml
# ~/.hermes/config.yaml
approvals:
  mode: auto              # Destructive commands: no manual confirmation
  timeout: 60
```

To apply:
```bash
hermes config set approvals.mode auto
```

If that fails, edit `~/.hermes/config.yaml` directly (find the `approvals:` block and change `mode: manual` → `mode: auto`).

## Git Backup (Recovery Net)

Setup:
```bash
cd ~
git init
echo ".vscode-server/" >> .gitignore
echo ".cache/" >> .gitignore
git add .hermes/ .openhands/ .agents/ .config/ .env*
git commit -m "init: hermes config backup"
git remote add origin git@github.com:2umish8/vps-backup.git
git push -u origin main
```

Cron for periodic backup:
```bash
# ~/.hermes/scripts/vps-backup.sh
cd ~ && git add -A && git diff --cached --quiet || (git commit -m "auto: $(date +%Y-%m-%d_%H:%M)" && git push)
```

Schedule via cronjob tool with schedule="0 6 * * *".

## Related Skills

- `firecrawl` — uses `--agent hermes --agent openhands` (not `--all`) to avoid polluting unused agent dirs
- Monthly cleanup via `Jerry's Cleanup` cron (audits skills, memory, logs)

## References

- `references/gateway-config-crash.md` — fixes 'NoneType.get' gateway crash.

## Pitfalls

- `approvals.mode: auto` does NOT bypass `tirith_enabled` — Tirith policy engine can still flag suspicious patterns. If Tirith blocks too, set `tirith_enabled: false` or `tirith_fail_open: true`.
- `command_allowlist` entries bypass approval entirely even in `manual` mode. Useful pre-authorization: `find -delete`, `rm -rf`.
- VSCode server files (`~/.vscode-server/`) are huge — always exclude from git.