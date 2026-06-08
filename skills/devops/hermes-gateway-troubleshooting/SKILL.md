---
name: hermes-gateway-troubleshooting
description: "Diagnose and fix common Hermes Gateway issues — Telegram, Discord, and other platforms."
version: 1.1.0
author: Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [gateway, troubleshooting, telegram, diagnostics, debugging]
    related_skills: [hermes-agent, gateway-customization, systematic-debugging]
---

# Hermes Gateway Troubleshooting

Diagnostic patterns for Hermes Gateway issues. Use when the gateway is running but not responding correctly, messages are lost, or slash commands behave differently from normal text messages.

## Key Diagnostic Clue: Slash Commands Work, Normal Messages Don't

This symptom means the **LLM call path is broken** but the **local command handler** works. Slash commands are processed locally in the gateway; normal messages must call the LLM API.

### Step 1 — Check Model Config

The gateway reads model config from `~/.hermes/config.yaml` on startup, not from `/model` commands issued mid-session.

```bash
hermes config | grep -A4 "Model"
```

If the model/provider config points to a provider without valid API keys, normal messages will fail silently.

**Fix:**
```bash
hermes config set model.default "provider/model-name"
hermes config set model.provider "provider-name"
hermes config set model.base_url ""   # clear custom URL if switching providers
hermes gateway restart
```

The `/model` slash command in a Telegram session only changes the model for THAT session — it does not persist to the gateway's config.

### Step 2 — Check Journal for RuntimeWarning (Missing await)

The `RuntimeWarning: coroutine '...' was never awaited` is a **critical signal** that an async function is being called without `await`, short-circuiting message processing.

```bash
journalctl --user -u hermes-gateway.service --since "1 hour ago" --no-pager | grep -i "runtimewarn\|never awaited"
```

**Common instance: `_maybe_handle_feedback` in `telegram.py`**

When a coroutine is called without `await`, Python returns a coroutine object (always truthy). The `if coroutine:` condition is always `True`, so the method `return` immediately — the normal message never reaches `_enqueue_text_event()`.

```python
# BUG: missing await
if self._maybe_handle_feedback(msg):   # returns truthy coroutine object
    return

# FIX:
if await self._maybe_handle_feedback(msg):
    return
```

**Why this hits text messages but not commands:** `_handle_text_message` has the `_maybe_handle_feedback` check, but `_handle_command` does not — slash commands bypass the bug entirely.

#### Fix

```bash
# Find the line with the missing await
grep -n "_maybe_handle_feedback" ~/.hermes/hermes-agent/gateway/platforms/telegram.py

# Add await before the call
# Line ~5215: change   if self._maybe_handle_feedback(msg):
#         to:   if await self._maybe_handle_feedback(msg):

# Restart gateway
hermes gateway restart
```

> **IMPORTANT trap:** After fixing the await bug, a SECOND bug may surface immediately — see Step 3 below. The await bug was **masking** the import-scoping bug; fixing one can reveal the other.

### Step 3 — Check for Import-Scoping UnboundLocalError

After fixing a missing `await`, if the user now sees `UnboundLocalError: cannot access local variable 'Platform'` on Telegram, this is the next bug.

```bash
# Find redundant local imports inside functions
grep -n "from gateway.config import Platform" ~/.hermes/hermes-agent/gateway/run.py
```

Check if any occurrence is **inside a function body** (indented, after a `def`) and has `Platform.FOO` **before** it in that function. If yes, that's the bug.

**Root cause:** A `from gateway.config import Platform` statement inside a function body makes Python treat `Platform` as a **local variable** for the entire function. Code that references `Platform.XXX` before the local import executes hits `UnboundLocalError` because the local hasn't been assigned yet.

`Platform` is already imported at **module level** (~line 1035 of `run.py`), so the local import is redundant and harmful.

#### Fix

```patch
# DELETE this line entirely — it's redundant:
-                    from gateway.config import Platform
```

Then restart:

```bash
hermes gateway restart
```

**Why this only appears after fixing the await bug:** The await bug in `_handle_text_message` caused a `return` before the agent loop was ever called. The `UnboundLocalError` in `_handle_message_with_agent` was never reached. Fixing the await bug unmasks the import-scoping bug.

## Approval Buttons Not Showing in Telegram

When the gateway responds to text messages but **the inline approval buttons (✅ Allow Once / ✅ Session / ✅ Always / ❌ Deny) never appear** when the agent wants to run a dangerous command, the cause is almost always the YAML boolean parsing of `approvals.mode`.

### Root Cause

YAML 1.1 (used by Hermes config) parses bare words like `off`, `false`, `no` as **boolean** values. If `config.yaml` has:

```yaml
approvals:
  mode: false
```

The value `false` loads as Python `False`, and `_normalize_approval_mode()` in `tools/approval.py` converts **boolean** `False` → `"off"`, completely disabling the approval flow:

```python
# tools/approval.py, line 832-833
if isinstance(mode, bool):
    return "off" if mode is False else "manual"
```

When mode is `"off"`, `_approval_notify_sync` in the gateway is never called, so Telegram's `send_exec_approval()` (which renders the inline keyboard with ✅/❌ buttons) is never invoked.

### Diagnosis

```bash
# Check the actual YAML value
grep -A2 "approvals:" ~/.hermes/config.yaml

# If it shows 'mode: false' or 'mode: off' (unquoted, YAML syntax-highlighted
# as a keyword rather than a string), you have the boolean trap.
```

### Fix

```bash
# Set mode to quoted string "manual" or "smart"
hermes config set approvals.mode "manual"

# MUST restart the gateway — config is read at startup
hermes gateway restart
```

| Mode | Behaviour |
|------|-----------|
| `"manual"` | Always show approval buttons for dangerous commands |
| `"smart"` | Auto-approve low-risk commands via auxiliary LLM, prompt for dangerous ones |
| `"off"` | No approval prompts at all — commands run immediately |

**Pitfall:** Running `hermes config set approvals.mode off` WITHOUT quotes writes the YAML boolean again. Always quote the value: `"manual"`, `"smart"`, or `"off"`.

### How the Approval Buttons Flow Works

1. Agent calls `terminal(command="rm -rf ...")` via the approval system
2. `detect_dangerous_command()` matches a `DANGEROUS_PATTERNS` pattern
3. If mode is `"manual"` or `"smart"` (and the smart LLM doesn't auto-approve), the agent thread blocks
4. `_approval_notify_sync()` checks if the adapter class has `send_exec_approval` (line 17707 of `gateway/run.py`)
5. Telegram adapter's `send_exec_approval()` (~line 2647 of `gateway/platforms/telegram.py`) sends the inline keyboard
6. Buttons fire `resolve_gateway_approval()` callback_data via `ea:once:N`, `ea:session:N`, `ea:always:N`, `ea:deny:N`
7. User clicks a button → agent thread unblocks

## Quick Golden Path

When a gateway is running but not responding to normal messages:

```bash
# 1. Check model config
hermes config | grep -A4 "Model"

# 2. Fix model if pointing to wrong provider
hermes config set model.default "deepseek/deepseek-v4-flash"
hermes config set model.provider "openrouter"
hermes config set model.base_url ""

# 3. Check for coroutine bugs
journalctl --user -u hermes-gateway.service --since "30 min ago" | grep -i "never awaited"

# 4. If found, locate the missing await
grep -n "_maybe_handle_feedback" ~/.hermes/hermes-agent/gateway/platforms/telegram.py

# 5. Check for import-scoping bug
grep -n "from gateway.config import Platform" ~/.hermes/hermes-agent/gateway/run.py

# 6. Restart after all fixes
hermes gateway restart
```

## Systemd Environment Configuration

To set permanent environment variables (like `HERMES_YOLO_MODE=1`) for the Hermes Gateway service, edit the service file:
`/home/hermes/.config/systemd/user/hermes-gateway.service`

Add the environment line in the `[Service]` section:
`Environment="HERMES_YOLO_MODE=1"`

Then restart the service:
`systemctl --user daemon-reload`
`systemctl --user restart hermes-gateway.service`

### Gateway running but not responding at all
- Check `.env` for TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS
- `hermes doctor` for dependency check
- `systemctl --user status hermes-gateway.service` for systemd state

### Gateway crash loop
```bash
systemctl --user reset-failed hermes-gateway.service
hermes gateway restart
```

### Dead Gateway on SSH logout
```bash
sudo loginctl enable-linger $USER
```

## References

- `references/telegram-await-bug-pattern.md` — Full reproduction and fix of the `_maybe_handle_feedback` missing-await bug
- `references/gateway-unbound-local-error-pattern.md` — Full reproduction and fix of the import-scoping `UnboundLocalError` bug
- `references/approval-buttons-yaml-boolean-trap.md` — YAML boolean parsing trap for `approvals.mode` and the inline approval button flow
