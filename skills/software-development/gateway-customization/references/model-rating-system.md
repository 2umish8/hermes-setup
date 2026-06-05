# Model Rating System — Reference Implementation

Complete worked example of extending the Hermes Telegram gateway with a
hybrid rating system (reactions + text feedback + slash commands).

## Files Created/Modified

| File | Change | Purpose |
|------|--------|---------|
| `gateway/model_rating.py` | NEW | Storage module: JSON-based rating store, bot message tracking, pending feedback state |
| `gateway/platforms/telegram.py` | MODIFIED | +`MessageReactionHandler`, +`_handle_rating_callback`, +`_maybe_handle_feedback`, +message tracking in `send()` |
| `gateway/run.py` | MODIFIED | +model injection into adapter, +`/ratings` slash command dispatch & handler |
| `hermes_cli/commands.py` | MODIFIED | +`CommandDef("ratings", ...)` registration |

## Architecture

```
User reacts 👍 on bot message
  → MessageReactionHandler fires
  → _handle_message_reaction() extracts emoji + user + message_id
  → record_reaction() looks up model from bot_messages tracking
  → Saved to ~/.hermes/model_ratings.json

User clicks 📝 button on bot message
  → _handle_callback_query dispatches "mr:msg_id"
  → _handle_rating_callback() sets pending feedback state
  → User replies with text
  → _maybe_handle_feedback() intercepts, records, confirms

User types /ratings
  → _handle_message() dispatches to _handle_ratings_command()
  → format_summary() / format_best_worst() reads JSON, builds markdown
```

## Reaction Emoji Mapping

| Emoji | Score | Meaning |
|-------|-------|---------|
| 👍 | +1 | Good |
| 👎 | -1 | Bad |
| 🤯 | +2 | Mind-blowing |
| 🗑️ | -2 | Garbage |
| 🔥 | +2 | Fire |
| ❤️ | +2 | Love |
| 💀 | -1 | Dead |
| 💩 | -2 | Crap |

## Key Design Decisions

1. **`_current_model` attribute on adapter**: The gateway runner sets `adapter._current_model` before the response is sent. The adapter's `send()` reads it to track which model generated which message. This avoids threading issues and doesn't require modifying `_process_message_background` in base.py.

2. **Separate pending feedback state**: `~/.hermes/model_rating_pending_feedback.json` stores `{chat_id:user_id → {message_id, model}}`. One pending feedback per user per chat. Cleared on use.

3. **JSON over SQLite**: Chose JSON for simplicity — readable, versionable, no migrations. Cleanup keeps last 5000 bot messages. Ratings file grows but slowly (~200 bytes per entry).

4. **`_maybe_handle_feedback` returns bool**: If the user has pending feedback, the text message is consumed and NOT passed to the agent. Commands (starting with `/`) are exempt — they pass through normally.

## Verification

```bash
# Test imports
cd ~/.hermes/hermes-agent
python -c "from gateway.model_rating import *; print('OK')"

# Check syntax
python -c "import ast; ast.parse(open('gateway/platforms/telegram.py').read()); print('OK')"
python -c "import ast; ast.parse(open('gateway/run.py').read()); print('OK')"
python -c "import ast; ast.parse(open('hermes_cli/commands.py').read()); print('OK')"

# Test functionality
python -c "
from gateway.model_rating import *
register_bot_message('123', '456', 'deepseek/v4', 'test')
record_reaction('123', '456', 'u1', '👍')
print(format_summary()[:200])
"
```

## Restart Required

After deploying, restart the gateway:
```bash
hermes gateway restart
```

## Remaining Work

- The 📝 inline button is handled by `_handle_rating_callback` but not yet visually attached
  to bot messages. This requires either:
  (a) Adding a `reply_markup` parameter to `send()` and passing it from `_process_message_background`, or
  (b) Using `register_post_delivery_callback` to edit the message after sending and add the button.

- Enable reactions in config: add `TELEGRAM_REACTIONS=true` to `~/.hermes/.env`.
