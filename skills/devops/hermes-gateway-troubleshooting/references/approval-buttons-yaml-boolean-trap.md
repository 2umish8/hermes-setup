# Approval Buttons: YAML Boolean Trap in `approvals.mode`

## The Trap

In `~/.hermes/config.yaml`:

```yaml
approvals:
  mode: false          # ← YAML 1.1 boolean! Becomes Python False
  mode: off            # ← Same trap — also boolean False in YAML 1.1
  mode: "manual"       # ← Correct: quoted string
  mode: "smart"        # ← Correct: quoted string
```

When the value enters `_normalize_approval_mode()` as a Python `bool`, the function (line 832-833 of `tools/approval.py`) converts `False` → `"off"`:

```python
def _normalize_approval_mode(mode) -> str:
    if isinstance(mode, bool):
        return "off" if mode is False else "manual"
    ...
```

## Why `hermes config set` matters

`hermes config set approvals.mode "manual"` writes the *quoted* string `"manual"` to YAML, which loads back as the string `"manual"`. But `hermes config set approvals.mode manual` (without quotes at the shell level) also works — the CLI serializer is string-safe. The trap is when you *hand-edit* YAML or use `hermes config set approvals.mode off` which YAML 1.1 parses as boolean.

## The `hermes config set` output is safe

The YAML serializer used by `hermes_cli/config.py` uses `ruamel.yaml` which respects string quoting. When you run `hermes config set approvals.mode "manual"`, it writes the YAML as:

```yaml
approvals:
  mode: manual
```

No quotes in the YAML output (ruamel strips them when the string doesn't need quoting), but the *semantics* are correct — it's a YAML string, not a boolean.

## The Approval Button Flow in Detail

### Gateway Side (`gateway/run.py`)

Line ~17684 — `_approval_notify_sync`:
```python
def _approval_notify_sync(approval_data: dict) -> None:
    # ...
    # Check the *class* for the method, not the instance
    if getattr(type(_status_adapter), "send_exec_approval", None) is not None:
        # Schedule the async call
        _approval_fut = safe_schedule_threadsafe(
            _status_adapter.send_exec_approval(
                chat_id=_status_chat_id,
                command=cmd,
                session_key=_approval_session_key,
                description=desc,
                metadata=_status_thread_metadata,
            ),
            _loop_for_step,
        )
```

### Telegram Side (`gateway/platforms/telegram.py`)

Line ~2647 — `send_exec_approval`:
```python
async def send_exec_approval(self, chat_id, command, session_key,
                              description="dangerous command", metadata=None):
    keyboard = InlineKeyboardMarkup([
        [
            InlineKeyboardButton("✅ Allow Once", callback_data=f"ea:once:{approval_id}"),
            InlineKeyboardButton("✅ Session", callback_data=f"ea:session:{approval_id}"),
        ],
        [
            InlineKeyboardButton("✅ Always", callback_data=f"ea:always:{approval_id}"),
            InlineKeyboardButton("❌ Deny", callback_data=f"ea:deny:{approval_id}"),
        ],
    ])
    kwargs = {
        "chat_id": int(chat_id),
        "text": text,
        "parse_mode": ParseMode.HTML,
        "reply_markup": keyboard,
    }
```

### Approval State Tracking

The Telegram adapter tracks pending approvals via `_approval_state` dict (line ~479):
```python
# Approval button state: message_id → session_key
self._approval_state: Dict[int, str] = {}
```

Approval IDs are generated via `itertools.count(1)` (line ~2676), stored in `_approval_state[approval_id] = session_key` (line ~2712), and looked up in `_handle_callback_query` when the user clicks a button.

## Common Misconfigurations

| What you wrote | YAML parses as | `_normalize` result | Effect |
|---|---|---|---|
| `mode: false` | `False` (bool) | `"off"` | ❌ No buttons |
| `mode: off` | `False` (bool) | `"off"` | ❌ No buttons |
| `mode: no` | `False` (bool) | `"off"` | ❌ No buttons |
| `mode: "manual"` | `"manual"` (str) | `"manual"` | ✅ Buttons appear |
| `mode: "smart"` | `"smart"` (str) | `"smart"` | ✅ Auto/low-risk skip |
| `mode: "off"` | `"off"` (str) | `"off"` | ❌ No buttons (intentional) |
| `mode: manual` | `"manual"` (str) | `"manual"` | ✅ Unquoted string OK |
| `mode: true` | `True` (bool) | `"manual"` | ✅ Surprising but works |

The last row is an edge case: YAML `true` becomes `True` (bool), and `_normalize` maps `True` → `"manual"`. Not recommended but functionally correct.