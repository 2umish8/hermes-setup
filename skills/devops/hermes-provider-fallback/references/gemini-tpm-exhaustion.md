# Gemini TPM Exhaustion — Real Session Reproduction

## Context
User had 3 Google Gemini API keys in a credential pool (fill_first strategy), all hitting 429 simultaneously while the primary model was `gemini-3.1-flash-lite-preview` with 15 fallback chain entries.

## Observed State

```bash
hermes auth list gemini
# gemini (3 credentials):
#   #1  GOOGLE_API_KEY       api_key env      rate-limited (429) (20m 31s left)
#   #2  alpha                api_key manual   rate-limited (429) (20m 36s left)
#   #3  nolann               api_key manual   rate-limited (429) (41m 33s left)
```

All 3 keys exhausted with nearly identical cooldowns (~20 min). Key #3 had 41 min suggesting it was tried later or got a different Retry-After from Google.

## Root Cause

Google AI Studio quotas showed:

| Account | Model | RPM | TPM | RPD | Verdict |
|---|---|---|---|---|---|
| Main | Flash Lite | 11/15 | **297.86K / 250K** | 72/500 | TPM over limit |
| Main | Flash | 1/5 | 32.2K / 250K | 3/20 | Fine |
| Nolann | Flash Lite | 9/15 | **278.35K / 250K** | 88/500 | TPM over limit |

RPM was fine (11/15, 9/15), but TPM was over 250K on both accounts. The burst came from Hermes' large context (system prompt + skills + memory + tool schemas + history) consuming ~20K+ tokens per exchange.

## Fallback Chain Behaviour

The fallback chain had 15 entries. The inter-credential switch DID work (fill_first: tried #1 → 429 → #2 → 429 → #3 → 429), but all within the same token burst so all 3 hit the 250K TPM wall. The per-provider fallback then fell through to Groq → Copilot → Mistral → OpenRouter entries, which worked fine.

## Mitigation Applied

```yaml
compression:
  enabled: true
  threshold: 0.15        # trigger at ~15% context fill (~150K for 1M limit)
  target_ratio: 0.2      # compress to 20% of original size
  protect_last_n: 3      # keep only 3 latest exchanges intact
```

Critical insight: `protect_last_n: 20` with `threshold: 0.15` is contradictory — 20 exchanges × ~20K tokens = 400K, which exceeds the 150K trigger point, so compression never fires.