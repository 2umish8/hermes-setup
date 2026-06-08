# Credential Management & Expiration Tracking

## Managing Multiple Keys for the Same Provider

When a provider has multiple accounts (e.g., free + Pro Gemini), store each under a distinct env var:

```bash
# ~/.hermes/.env
GOOGLE_API_KEY=AIzaSyAX...        # Original, expires 2026-10-16
GEMINI_PRO_API_KEY=AQ.Ab8RN...    # Pro account, expires ~2026-10-07
```

### Making Hermes use a specific key

Option A: **Credential pool** (auto-rotation)
```bash
hermes auth add    # Interactive wizard — adds to ~/.hermes/auth.json
```
Then set strategy in config.yaml:
```yaml
credential_pool_strategies:
  gemini: fill_first    # or round_robin, random
```

Option B: **Direct config** (single key)
```yaml
# config.yaml
model:
  api_key: GEMINI_PRO_API_KEY    # Env var name, not the value
```

Option C: **Fallback chain** (use second key as backup)
Not directly supported — fallback chains switch providers/models, not keys within the same provider. Use credential pool instead.

## Expiration Tracking with Cron

For keys with known expiration dates, create one-shot cron jobs:

```python
# 1 week before expiration — warning
cronjob(action="create",
    schedule="2026-10-09T09:00:00",
    name="Key expiration warning",
    prompt="⚠️ KEY_NAME expires in ~1 week (DATE). Check renewal.",
    deliver="telegram")

# Day of expiration — alert
cronjob(action="create",
    schedule="2026-10-16T09:00:00",
    name="Key expired",
    prompt="🚨 KEY_NAME expired today. Comment/remove from .env.",
    deliver="telegram")
```

## .env Recovery from State Snapshots

If `.env` is accidentally overwritten, check:
```bash
ls ~/.hermes/state-snapshots/
# Each contains a full .env backup taken before Hermes updates
cat ~/.hermes/state-snapshots/YYYYMMDD-HHMMSS-pre-update/.env
```

Extract the original key:
```python
with open('state-snapshots/<snapshot>/.env') as f:
    for line in f:
        if line.startswith('ORIGINAL_KEY_NAME'):
            original = line.strip().split('=', 1)[1]
```

## Key Format Reference

| Provider | Key format | Length |
|---|---|---|
| Google AI Studio | `AIzaSy...` | 39 chars |
| Google OAuth/Service | `AQ.Ab8...` | 53 chars |
| OpenRouter | `sk-or-...` | 64+ chars |
| Groq | `gsk_...` | 56 chars |
| Mistral | varies | 32+ chars |
