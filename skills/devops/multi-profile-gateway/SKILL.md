---
name: multi-profile-gateway
description: "Run multiple Hermes profiles with separate Telegram bots, systemd services, and cross-profile awareness. Use when the user wants a second bot persona, separate agent instances on the same machine, or cross-profile session visibility."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [profiles, gateway, telegram, multi-agent, systemd, persona]
    related_skills: [hermes-agent, native-mcp, todoist-integration]
---

# Multi-Profile Gateway

Run multiple independent Hermes Agent instances on the same machine, each with its own Telegram bot, persona, config, skills, memory, and cron jobs — but sharing the same codebase and Python environment.

## When to Use

- User wants a **separate bot persona** (accountability partner, project-specific assistant, team bot)
- Need **isolated conversations** per purpose (work vs personal, tech vs coaching)
- Want **cross-profile awareness** (one bot can see what another bot's user worked on)
- Running **multiple Telegram bots** on the same VPS

## Architecture

```
User ← Telegram → [Default Gateway]  (hermes-gateway.service, PID X)
  ↕ session_search(profile='default')

User ← Telegram → [Profile Gateway]  (hermes-gateway-NAME.service, PID Y)
  ↕ session_search(profile='NAME')
```

Each profile has:
- Own `~/.hermes/profiles/NAME/config.yaml`
- Own `.env` (API keys, Telegram token)
- Own `SOUL.md` (persona / system prompt)
- Own `skills/`, `memories/`, `cron/`, `sessions/`
- Own systemd service: `hermes-gateway-NAME.service`

## Setup Steps

### 1. Create Profile

```bash
hermes profile create NAME --clone
# Clones config, .env, SOUL.md, skills from default profile
```

### 2. Create Telegram Bot

Via @BotFather on Telegram:
1. `/newbot`
2. Set name and username
3. Copy the token

### 3. Configure the Profile

Edit `~/.hermes/profiles/NAME/config.yaml`:

```yaml
model:
  default: openai/gpt-4.1-mini    # or whatever model
  provider: openrouter

telegram:
  bot_token: "BOT_TOKEN_HERE"      # unique per profile!
  reactions: false
  channel_prompts: {}
  allowed_chats: ""

# Different API server port to avoid conflicts
api_server:
  port: 8643                       # default is 8642

# MCP servers (if needed)
mcp_servers:
  todoist:
    command: npx
    args: ["-y", "@doist/todoist-mcp"]
    env:
      TODOIST_API_KEY: "token-here"
```

Also add to `~/.hermes/profiles/NAME/.env`:
```
TELEGRAM_BOT_TOKEN=<token>
```

### 4. Write the Persona

Edit `~/.hermes/profiles/NAME/SOUL.md` with the bot's personality, communication style, and behavioral rules.

### 5. Install & Start Gateway

```bash
echo -e "Y\nY" | hermes gateway install --profile NAME
```

Or manually:
```bash
systemctl --user start hermes-gateway-NAME
```

### 6. Add Cron Jobs

Write directly to `~/.hermes/profiles/NAME/cron/jobs.json` (see `todoist-integration` skill's `references/todoist-cron-jobs.md` for format). Then restart:

```bash
systemctl --user restart hermes-gateway-NAME
```

## Management Commands

```bash
# Status
systemctl --user status hermes-gateway-NAME

# Restart (cannot use `hermes gateway restart` from inside the gateway)
systemctl --user restart hermes-gateway-NAME

# Stop
systemctl --user stop hermes-gateway-NAME

# Logs
journalctl --user -u hermes-gateway-NAME -f

# Cron jobs
hermes --profile NAME cron list
```

## Cross-Profile Awareness

A profile's agent can read sessions from other profiles using `session_search`:

```python
session_search(profile='default')           # read main profile sessions
session_search(profile='default', query="mowtif")  # search specific topic
```

This enables patterns like:
- **Accountability bot** checks what user worked on in main profile
- **Project bot** sees context from personal conversations
- **Team bot** can reference private planning sessions

Embed in cron prompts: `session_search(profile='default')` to give the secondary bot visibility.

## Pitfalls

### Telegram Token Conflicts
Each profile MUST have a **unique** bot token. Two profiles sharing a token causes: `Telegram bot token already in use (PID ...)`. Set the token in BOTH `config.yaml` (`telegram.bot_token`) AND `.env` (`TELEGRAM_BOT_TOKEN`).

### API Server Port Conflicts
Each profile needs a different `api_server.port`. Default is 8642; use 8643, 8644, etc. Without this, you get: `Port 8642 already in use`.

### Gateway Restart from Inside Gateway
`hermes gateway restart` and `hermes gateway stop` refuse to run from inside a gateway session (prevents restart loops). Always use `systemctl --user restart hermes-gateway-NAME` instead.

### `hermes cron create --profile` CLI Bug
The `--profile` flag on the global `hermes` parser conflicts with the `cron create` subparser's positional `prompt` argument. The prompt gets consumed by the global parser. **Workaround**: Write `jobs.json` directly to `~/.hermes/profiles/NAME/cron/jobs.json`.

### Gateway Install Prompts
`hermes gateway install --profile NAME` asks Y/N twice. Pipe answers: `echo -e "Y\nY" | hermes gateway install --profile NAME`.

### Shared Python Environment
All profiles share the same venv at `~/.hermes/hermes-agent/venv/`. MCP servers (npx packages) are also shared. This is fine for most cases but means all profiles run the same Hermes version.

### Memory Isolation
Each profile has completely isolated memory (`memories/`, `user_profile.md`). The default profile's memory does NOT leak into other profiles. If the secondary bot needs to know about the user, write a `memories/user_profile.md` in that profile's directory.

## References

See `references/systemd-service-template.md` for the auto-generated service file structure.
