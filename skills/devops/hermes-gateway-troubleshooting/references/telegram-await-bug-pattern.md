# Telegram Await Bug Pattern

## Symptom

Gateway processes slash commands (`/restart`, `/model`, `/reset`, etc.) correctly but ignores normal text messages entirely — no response, no error in gateway.log.

## Root Cause

Missing `await` on an async method call in `gateway/platforms/telegram.py`.

## Discovery Path

1. User reported: messages like "Test" get no reply on Telegram
2. Gateway logs showed no errors — clean startup, connected OK
3. Model config pointed to Gemini (no valid key) — first thought was API failure
4. Changed model to DeepSeek/OpenRouter — still didn't work
5. Checked `journalctl` for systemd-level warnings:

   ```
   $ journalctl --user -u hermes-gateway.service --since "1 hour ago" | grep -i warn
   RuntimeWarning: coroutine 'TelegramAdapter._maybe_handle_feedback' was never awaited
   ```

6. Traced the code:

   **telegram.py line 3256:**
   ```python
   async def _maybe_handle_feedback(self, msg) -> bool:
   ```

   **telegram.py line 5215 (the bug):**
   ```python
   if self._maybe_handle_feedback(msg):    # ← No await!
       return
   ```

## Why This Happens

- `_maybe_handle_feedback` is declared `async def` (returns a coroutine)
- Calling it without `await` returns a **coroutine object** (always truthy)
- `if <coroutine_object>:` is always `True`
- `return` is always reached — the message **never** reaches `self._enqueue_text_event(event)`

## Why Slash Commands Still Work

The bug is in `_handle_text_message` (line ~5200). Slash commands go through `_handle_command` (line ~5229), which does NOT have the `_maybe_handle_feedback` check — they bypass the bug completely.

## Fix

```patch
- if self._maybe_handle_feedback(msg):
+ if await self._maybe_handle_feedback(msg):
```

## Verification

After fix + restart:

```bash
journalctl --user -u hermes-gateway.service --since "2 min ago" | grep -i "never awaited"
# → empty output = fix confirmed
```

## Affected Version

Found in hermes-agent at commit as of 2026-06-01. The bug exists wherever `_maybe_handle_feedback` is called from a non-async context — always check for `await` presence.

## Code Flow

```
Telegram update arrives
  → _handle_text_message() [line ~5210]
    → msg = self._effective_update_message(update)
    → if not msg or not msg.text: return
    → BUG: if self._maybe_handle_feedback(msg): return   ← ALWAYS returns
    → NEVER reaches:
      - self._ensure_forum_commands(update.message)
      - self._build_message_event(msg, MessageType.TEXT)
      - self._enqueue_text_event(event)
```
