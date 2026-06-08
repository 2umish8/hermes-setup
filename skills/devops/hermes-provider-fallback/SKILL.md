---
name: hermes-provider-fallback
description: Configure Hermes provider fallback chains, credential pools, and free/cheap AI provider rotation. Use when setting up fallback_providers, adding free providers like Groq or Mistral, troubleshooting rate-limit exhaustion, or building a "rat pauvre" cost-optimized chain.
version: 1.1.0
---

# Hermes Provider Fallback

How fallback chains work in Hermes, which free providers are available, and how to build a cost-optimized chain.

**References:** [`references/gemini-tpm-exhaustion.md`](references/gemini-tpm-exhaustion.md) — reproduction d'un cas réel d'épuisement TPM Gemini avec commandes et données Google AI Studio.

## Quick Reference

```bash
hermes fallback list          # Show current chain
hermes fallback add           # Interactive picker (same as `hermes model`)
hermes fallback remove        # Remove one entry
hermes fallback clear         # Remove all
hermes auth list              # Show credential pools per provider
```

## Fallback Architecture

- **Per-request**, not per-session. Each API call starts fresh with the primary provider.
- When a provider fails (rate-limit 429, 5xx, auth error, timeout), the credential pool marks that credential **exhausted** with a cooldown timer.
- The system falls through `fallback_providers` in order.
- **When cooldown expires, the provider becomes available again** on the next request. No "permanent fallthrough to last resort."

### Config format (`config.yaml`)

```yaml
fallback_providers:
  - provider: openrouter
    model: deepseek/deepseek-v4-pro
  - provider: gemini
    model: gemini-2.5-flash-lite
  - provider: custom:groq
    model: llama-3.1-8b-instant
    base_url: https://api.groq.com/openai/v1
```

### Credential Pool Strategies (`config.yaml`)

```yaml
credential_pool_strategies:
  openrouter: fill_first    # Use first credential until exhausted, then next (default)
  gemini: round_robin       # Rotate evenly across all credentials
  custom:groq: random       # Random selection
```

Strategies: `fill_first` (default), `round_robin`, `random`.

## Free Providers (2026)

| Provider | How to use in Hermes | Rate limit | Best free models |
|---|---|---|---|
| **Groq** | Custom endpoint (`custom:groq`, base_url `https://api.groq.com/openai/v1`) | 250K TPM, 1K RPM | `llama-3.1-8b-instant` (560 t/s), `openai/gpt-oss-20b` (1000 t/s) |
| **Gemini** | Native (`gemini`) | 15 RPM, 1000/day (Pro) | `gemini-2.5-flash-lite`, `gemini-2.5-flash` |
| **GitHub Copilot** | Native (`copilot`) via `gh auth token` | ~50/day | `claude-sonnet-4`, `gpt-4o` |
| **Mistral** | Native (`mistral`) | Experiment tier | `mistral-small-latest`, `mistral-large-latest` |
| **HuggingFace** | Native (`huggingface`) | Free tier, cold starts | Thousands of open-source models |

### Groq as Custom Provider

Groq is NOT a native Hermes provider. Set it up as a custom endpoint:

1. Add `GROQ_API_KEY` to `~/.hermes/.env`
2. Add to `fallback_providers`:
```yaml
  - provider: custom:groq
    model: llama-3.1-8b-instant
    base_url: https://api.groq.com/openai/v1
```

For multiple Groq models as separate fallback entries (some providers enforce per-model rate limits):
```yaml
  - provider: custom:groq
    model: llama-3.1-8b-instant
    base_url: https://api.groq.com/openai/v1
  - provider: custom:groq
    model: openai/gpt-oss-20b
    base_url: https://api.groq.com/openai/v1
```

## Cost-Optimized Chain Pattern ("Rat Pauvre")

```
Primary:     Groq (free, fast, lightweight models)
Fallback 1:  Groq model #2 (different rate limit bucket)
Fallback 2:  Groq model #3
Fallback 3:  Gemini Flash (free tier, generous limits)
Fallback 4:  GitHub Copilot (free, limited daily quota)
Fallback 5:  OpenRouter with cheapest model (paid, last resort)
```

Key insight: list multiple models from the same free provider because some providers enforce per-model rate limits. If `llama-3.1-8b-instant` is rate-limited, `gpt-oss-20b` may still be available.

## Diagnosing Rate Limits: TPM vs RPM

When debugging "why did all my credentials get 429 at once?", check **both** TPM (tokens/min) and RPM (requests/min). They exhaust independently.

### Common pattern: TPM burst exhaustion

Hermes sends large prompts (system prompt + skills + memory + tool schemas + conversation history). A single exchange can consume 15-25K tokens. In 4-5 exchanges you hit 100K+ tokens. Free tier limits:

| Provider | TPM limit | RPM limit | Burst triggers |
|---|---|---|---|
| Gemini (free) | 250K TPM | 15-30 RPM | Context-heavy sessions |
| Groq (free) | 250K TPM | 1K RPM | Tool-heavy workflows |

**Symptoms of TPM exhaustion:**
- All credentials for a provider get 429 simultaneously (or in quick succession)
- `hermes auth list` shows identical cooldown timers (±a few minutes)
- Google AI Studio console shows TPM bars near/over limit while RPM is still low

**Why all keys burn together:** With `fill_first` (default pool strategy), each request tries credential #1 → 429 → credential #2 → 429 → credential #3 → 429 in rapid succession. The same burst of tokens hits each key sequentially, so they all exhaust within seconds. This is expected behavior — the cooldown system is doing its job, but a TPM burst is too fast for sequential fallback to dodge.

### How to diagnose

```bash
hermes auth list <provider>   # Shows 429 status + cooldown remaining per credential
hermes fallback list          # Shows which provider/model is tried next
```

Check the provider's dashboard (e.g. Google AI Studio):
- TPM near/over limit but RPM well under → **TPM exhaustion** (most common with Hermes)
- RPM near/over limit but TPM fine → **RPM exhaustion** (rare, usually long-running batch jobs)

### Mitigations

| Mitigation | Effect | How |
|---|---|---|
| **Enable context compression** | Reduces tokens per exchange | `hermes config set compression.enabled true` + tune `threshold` (lower = sooner) + tune `protect_last_n` (fewer protected messages) |
| **Frequent `/new` or `/reset`** | Clears accumulated history | Start fresh sessions regularly |
| **Round-robin credential strategy** | Spreads across keys (less useful for TPM bursts) | `hermes config set credential_pool_strategies.<provider> round_robin` |
| **Upgrade to paid tier** | Raises TPM limit 10-40x (Gemini: 4M TPM) | Provider billing settings |
| **Move lightweight models to primary** | Groq's generous RPM absorbs bursts better | Use Groq as primary, Gemini as fallback |

### Compression tuning specifics

Key constraint: `protect_last_n × tokens_per_exchange` must be **below** `threshold × context_length`, otherwise compression never triggers.

```
Context limit:  1M tokens
threshold:      0.15 → triggers at 150K
protect_last_n: 3   → 3 exchanges × ~20K = 60K ✓ (under 150K)
protect_last_n: 20  → 20 exchanges × ~20K = 400K ✗ (over 150K, never triggers)
```

Always verify this math when tuning compression — too many protected messages silently disable it.

## Pitfalls

- **Groq is not native** — must use `custom:groq` with explicit `base_url`. The `hermes fallback add` wizard may not find it.
- **Copilot 403**: `gh auth login` tokens do NOT work for Copilot API. Must use Copilot-specific OAuth flow via `hermes model` → GitHub Copilot.
- **Same-provider rate limits**: If a provider enforces a global rate limit (not per-model), multiple fallback entries for that provider all fail together. Group by provider rate-limit scope.
- **`fill_first` burst trap**: When a session bursts 250K TPM in 5 exchanges, all pooled credentials exhaust in the same burst. Pool strategy affects steady-state distribution but not the first burst.