---
name: gateway-customization
description: Extend the Hermes Agent gateway with custom platform handlers, slash commands, and integrations. Covers Telegram adapter hooks, MessageReactionHandler, inline keyboard callbacks, and registering new gateway commands.
version: 1.1.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [gateway, telegram, extension, slash-commands, handlers, customization]
    related_skills: [hermes-agent]
---

# Gateway Customization

How to extend the Hermes Agent messaging gateway with custom platform features, handlers, and slash commands. Uses the model rating system as a worked example.

## Architecture Overview

The gateway has three layers where custom code can be injected:

| Layer | File | What to add |
|-------|------|-------------|
| **Platform adapter** | `gateway/platforms/telegram.py` | New handlers (reactions, callbacks, message types) |
| **Gateway runner** | `gateway/run.py` | Slash command dispatch + handler methods |
| **Command registry** | `hermes_cli/commands.py` | Command definitions for autocomplete/help |
| **Module** | `gateway/<feature>.py` | Standalone logic (storage, formatting, business rules) |

## Adding a Custom Telegram Handler

### 1. Check PTB support

Verify the handler class exists in the installed `python-telegram-bot`:

```python
python -c "from telegram.ext import MessageReactionHandler; print('Available')"
```

### 2. Register the handler

In `telegram.py`, inside the `start()` method where handlers are registered (~line 1565):

```python
self._app.add_handler(MessageReactionHandler(self._handle_message_reaction))
```

### 3. Implement the handler method

Add a new async method on the adapter class. Use `getattr` for Telegram update fields — they're not always present:

```python
async def _handle_message_reaction(self, update, context):
    reaction_update = getattr(update, 'message_reaction', None)
    if not reaction_update:
        return
    chat_id = str(getattr(getattr(reaction_update, 'chat', None), 'id', ''))
    # ... extract data, call your module
```

### 4. Handle imports gracefully

The file uses a try/except for PTB imports with `Any` fallbacks. Add new handler classes in both paths:

```python
try:
    from telegram.ext import (..., MessageReactionHandler, ...)
    ...
except ImportError:
    ...
    MessageReactionHandler = Any
```

And in the lazy-reimport block (~line 130), add the handler to both the reimport and rebinding.

## Adding Slash Commands

### 1. Register in command registry

In `hermes_cli/commands.py`, add a `CommandDef`:

```python
CommandDef("ratings", "Show model rating summary", "Configuration",
           args_hint="[best|worst]", subcommands=("best", "worst")),
```

### 2. Add dispatch in run.py

In the command dispatch section (~line 7470):

```python
if canonical == "ratings":
    return await self._handle_ratings_command(event)
```

### 3. Implement the handler

```python
async def _handle_ratings_command(self, event: MessageEvent) -> str:
    from gateway.model_rating import format_summary
    return format_summary()
```

## Passing Model Info to the Adapter

When a feature needs the current model name at send-time (e.g., tracking which model generated which message):

1. In `run.py`, after `_run_agent()` returns, set an attribute on the adapter:

```python
_model_name = agent_result.get("model", "")
if _model_name:
    adapter = self.adapters.get(source.platform)
    if adapter:
        adapter._current_model = _model_name
```

2. In the adapter's `send()` method, read it:

```python
_model = getattr(self, '_current_model', None)
if _model:
    register_bot_message(message_id=..., model=_model, ...)
```

## Diagnostic: Slash Commands Work But Text Messages Don't

This is the most common integration bug pattern. When `/slash` commands respond but normal text is silently ignored:

### 1. Check model config
Run `hermes config` — if the model/provider has no API key configured in `.env`, slash commands still work (they're local), but LLM calls fail silently.

### 2. Look for `async def` called without `await`
In `telegram.py`'s `_handle_text_message`, if an `async def` method is called as:
```python
if self._some_async_method(msg):   # ← BUG: missing await
    return
```
Python returns a coroutine object (always truthy), so the function returns immediately without enqueueing the message. Every text message is silently dropped. The fix:
```python
if await self._some_async_method(msg):  # ← CORRECT
```

### 3. Check for local-import shadowing
If `run.py` has a `from gateway.config import Platform` inside a function body that also references `Platform` before the import line, Python raises `UnboundLocalError` because it sees `Platform` as a local variable (the import) but it's used before the assignment.

## Pitfalls

- **`patch` tool escaping**: When using the `patch` tool on `run.py` or `telegram.py`, pass `old_string` and `new_string` without backslash-escaping quotes. Use raw `"` not `\"`. If you get "Escape-drift detected", re-read the target lines with `read_file` and match exactly.

- **`run.py` is 18K+ lines**: The file has many similar command dispatch blocks. Always provide enough unique surrounding context (3-5 lines) when using `patch` to avoid ambiguous matches.

- **`Platform` import in `run.py`**: `Platform` IS imported at module level (line ~1035). **Do NOT add `from gateway.config import Platform` inside a function body** unless it's the very first reference to `Platform` in that function — a local import makes Python treat `Platform` as a local variable for the whole function, causing `UnboundLocalError` when used before the import line. The safest approach: rely on the module-level import (it's already there).

- **Indentation in telegram.py**: Class methods are at 4-space indentation, method bodies at 8-space. When the `patch` tool inserts code inside an existing method, verify indentation is correct — the diff only shows what changed, not the surrounding nesting.

- **PTB version**: Check `telegram.__version__` before using newer handlers. `MessageReactionHandler` requires PTB ≥ 21.0 (confirmed available in 22.6).

- **`register_post_delivery_callback`**: Available on the base adapter but requires `session_key`, `callback`, and optional `generation` for stale-run safety. Use for post-send message edits (buttons, cleanup).

- **Missing `TELEGRAM_REACTIONS` env var**: The model rating system is fully wired but gated behind `TELEGRAM_REACTIONS=true` in `.env`. Without it, `_reactions_enabled()` returns False and all reaction/feedback handlers are skipped.

## Reference Implementation

See `references/model-rating-system.md` for the complete model rating system built with these patterns.
