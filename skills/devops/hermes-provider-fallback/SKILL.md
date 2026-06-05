---
name: hermes-provider-fallback
description: Configure Hermes provider fallback chains, credential pools, and free/cheap AI provider rotation. Use when setting up fallback_providers, adding free providers like Groq or Mistral, troubleshooting rate-limit exhaustion, or building a "rat pauvre" cost-optimized chain.
version: 1.0.0
---

# Hermes Provider Fallback

How fallback chains work in Hermes, which free providers are available, and how to build a cost-optimized chain.

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

## Pitfalls

- **Groq is not native** — must use `custom:groq` with explicit `base_url`. The `hermes fallback add` wizard may not find it.
- **Copilot 403**: `gh auth login` tokens do NOT work for Copilot API. Must use Copilot-specific OAuth flow via `hermes model` → GitHub Copilot.
- **Same-provider rate limits**: If a provider enforces a global rate limit (not per-model), multiple fallback entries for that provider all fail together. Group by provider rate-limit scope.