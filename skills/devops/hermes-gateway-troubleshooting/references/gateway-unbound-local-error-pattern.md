# Import-Scoping UnboundLocalError Bug Pattern

## Symptom

After fixing the missing-await bug, user sends a message on Telegram and gets:

```
Sorry, I encountered an error (UnboundLocalError).
cannot access local variable 'Platform' where it is not associated with a value
```

## Root Cause

A `from gateway.config import Platform` statement sits **inside** a function body, placed **after** code that references `Platform.FOO`. Python's compiler sees the local import assignment at compile time and treats `Platform` as a **local variable** for the entire function. At the point of first use, the local hasn't been assigned yet → `UnboundLocalError`.

## Discovery Path

1. After fixing the await bug in `telegram.py`, gateway was restarted
2. User sent "Test" from Telegram — got `UnboundLocalError: cannot access local variable 'Platform'`
3. Gateway log showed the traceback:

   ```
   File ".../gateway/run.py", line 9099, in _handle_message_with_agent
       if not history and source.platform and source.platform != Platform.LOCAL and source.platform != Platform.WEBHOOK:
   UnboundLocalError: cannot access local variable 'Platform' where it is not associated with a value
   ```

4. Traced the function body — found `from gateway.config import Platform` at line 9217 (inside a `try` block), which is **after** line 9099 where `Platform.LOCAL` is first accessed

5. `Platform` is already imported at **module level** (~line 1035) — the local import is redundant

## Code Flow

```python
# Function def at line 8537
async def _handle_message_with_agent(self, event, source, _quick_key, run_generation):
    ...

    # Line 9099 — FIRST use of Platform in this function
    if not history and source.platform and source.platform != Platform.LOCAL and source.platform != Platform.WEBHOOK:
        ...

    # Line 9125 — MORE uses of Platform
    if source.platform == Platform.DISCORD:
        ...

    # Line 9217 — REDUNDANT local import (AFTER first use)
    from gateway.config import Platform
    _tg_adapter = self.adapters.get(source.platform)
```

## Why This Happens

- Python determines variable scope at **compile time**, not runtime
- The `from ... import Platform` anywhere in the function makes `Platform` a **local name** for the entire function
- Any reference to `Platform` that appears **before** this import in execution order tries to read a local that hasn't been assigned yet

## Why It Only Appears After the Await Fix

The await bug was **masking** this one. Before fixing the await bug, `_handle_text_message` returned early (line 5216) before ever calling `_handle_message_with_agent` → the UnboundLocalError was never reached.

## Fix

Remove the redundant local import — `Platform` is already available at module level:

```patch
-                    from gateway.config import Platform
                      _tg_adapter = self.adapters.get(source.platform)
                      if _tg_adapter and source.platform == Platform.TELEGRAM:
```

After the fix, restart:

```bash
hermes gateway restart
```

## Verification

```bash
# Send "Test" from Telegram
tail -5 ~/.hermes/logs/gateway.log | grep -i "sending response"
# → should show "Sending response (N chars)"
```

## Other Occurrences

The same redundant pattern appears in other functions in `run.py`:
- `_handle_command_slash` (~line 10660) — safe because the import is the FIRST reference to `Platform` in that scope
- Some other handlers (~line 16662) — check if the import precedes all uses

Each is harmless only if the import is the first `Platform` reference in its function. These are safe but still unnecessary — `Platform` is always available at module level.

## Affected Version

Found in hermes-agent commit as of 2026-06-01. Any `from gateway.config import Platform` inside a function where `Platform.FOO` is used before the import will trigger this bug.