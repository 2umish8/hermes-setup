---
name: provider-fallback
description: Manage Hermes provider rotation and fallback chains — add free/paid providers, configure priority order, test API keys, and diagnose failures. Triggers on "provider rotation", "fallback chain", "change model", "add provider", "credential pool", "cheapest model", "free provider", "API key expired".
version: 1.0.0
---

# Provider Fallback Chain Management

How to set up and maintain Hermes' fallback provider chain for cost optimization
(free providers first, paid as last resort).

## Quick Reference: Fallback Chain Format

```yaml
# config.yaml
model:
  default: mistral-small-latest
  provider: custom:mistral

custom_providers:
  - name: mistral
    base_url: https://api.mistral.ai/v1
    api_key: MISTRAL_API_KEY

fallback_providers:
  - provider: custom:mistral
    model: open-mistral-nemo
  - provider: gemini
    model: gemini-2.5-flash-lite
  - provider: openrouter
    model: deepseek/deepseek-v4-pro
```

The fallback chain is **per-request** — each API call starts fresh with the primary
provider. Rate-limited providers enter cooldown (exhaustion) and become available
again when the cooldown expires. The system does NOT fall through to the last
resort and stay there.

## Adding a Non-Native Provider (Custom Endpoint)

Providers not natively supported (Groq, Mistral, Together AI) use the `custom`
provider plugin:

1. Add API key to `~/.hermes/.env`:
   ```
   MISTRAL_API_KEY=your_key_here
   ```

2. Add to `custom_providers` in `config.yaml`:
   ```yaml
   custom_providers:
     - name: mistral
       base_url: https://api.mistral.ai/v1
       api_key: MISTRAL_API_KEY
   ```

3. Reference in model or fallback as `custom:<name>`:
   ```yaml
   provider: custom:mistral
   ```

## Testing API Keys Before Committing

Always test keys with `curl` before adding to config. A non-working key in the
chain blocks the fallback at that tier.

```bash
# Test chat completions
curl -s -X POST https://api.mistral.ai/v1/chat/completions \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"mistral-small-latest","messages":[{"role":"user","content":"hi"}]}'

# Test models list (simpler endpoint)
curl -s https://api.groq.com/openai/v1/models \
  -H "Authorization: Bearer $KEY"
```

## Pitfalls

### api_key vs api_key_env
In `custom_providers`, the field is **`api_key`** (NOT `api_key_env`).
It references the env var name as a string — Hermes resolves it at runtime.

## Gateway Diagnostic Patterns

### Symptom: Slash commands work, normal messages silent

**Situation:** Gateway responds to `/restart`, `/model`, `/help`, etc. but regular text messages like "Test" get no response.

**Diagnosis chain:**
1. Slash commands are handled **locally** by the gateway process — no LLM API call needed. If they work, the gateway is running and connected to the platform.
2. Normal messages need an LLM API call. Silent failure = the API call is failing before the gateway can forward an error.
3. **Root cause in 90% of cases:** Model/provider misconfiguration. The `model.default` + `model.provider` in `config.yaml` point to a provider whose API key is missing, expired, or invalid.

**Check:**
```bash
hermes config | grep -A5 Model
```

**Fix:**
```bash
hermes config set model.default "correct-model-name"
hermes config set model.provider "correct-provider"    # e.g. openrouter, gemini, copilot
hermes config set model.base_url ""                     # clear if switching providers
hermes gateway restart
```

**Why this happens after a model switch:** Changing model via `/model` in a Telegram/CLI session only affects that session. The gateway reads `config.yaml` at startup — it needs an explicit config update + restart.

### Symptom: Gateway connected but gives "Bad Gateway" errors
```
Telegram network error, scheduling reconnect: Bad Gateway
```
Platform congestion or IP block. If persistent, check the fallback IP auto-discovery in logs. Usually self-resolving within minutes.

### Symptom: Config changes ignored after restart
```
WARNING gateway.config: Failed to process config.yaml — falling back to .env / gateway.json values
```
The config file has a YAML syntax error or an unexpected type (e.g. a string where a dict is expected). Run `hermes config check` or `hermes config edit` and look for structural issues like a bare string under `model.default` instead of a key-value pair.

### Groq Error 1010
`HTTP 403: error code: 1010` = API key expired or revoked.
Regenerate at https://console.groq.com/keys.

### Config File is Protected
`config.yaml` cannot be edited with `patch` or `write_file` tools — use the
`terminal` tool with Python YAML dump:
```python
import yaml
with open("/home/hermes/.hermes/config.yaml") as f:
    config = yaml.safe_load(f)
# ... modify ...
with open("/home/hermes/.hermes/config.yaml", "w") as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False)
```

### Changes Require Gateway Restart
Config changes take effect on next gateway restart (`/restart` from Telegram
or `hermes gateway restart` from CLI). They do NOT apply mid-session.

## Free Provider Landscape (2026)

| Provider | Access | Speed | Best model (free tier) |
|---|---|---|---|
| Groq | Free tier, rate-limited | ~560-1000 t/s | llama-3.1-8b-instant |
| Mistral | Experiment tier | Moderate | mistral-small-latest |
| Gemini | AI Studio free tier | Fast | gemini-2.5-flash-lite |
| Copilot | GitHub token | Moderate | claude-sonnet-4 |

## Cost-Optimized Chain Template

```
PRIMARY:  Groq (llama-3.1-8b-instant)        ← Fastest free
    →     Groq (gpt-oss-20b)                  ← Backup model
    →     Mistral (mistral-small-latest)      ← Free tier
    →     Gemini (gemini-2.5-flash-lite)      ← Free tier
    →     Gemini (gemini-2.5-flash)           ← Free tier
    →     Copilot (claude-sonnet-4)           ← Free via gh token
    →     OpenRouter (cheapest model)         ← PAID, last resort
```

## See Also

- [Groq model reference](references/groq-models.md) — model IDs, speeds, rate limits, pricing
- [Hermes fallback docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/fallback-providers)