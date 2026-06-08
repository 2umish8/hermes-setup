# Gemini API Key Diagnostics

Google's Generative Language API has distinct error codes that map to different root causes.

## Error Codes

| HTTP | Status | Message | Root Cause |
|------|--------|---------|------------|
| 403 | PERMISSION_DENIED | "Method doesn't allow unregistered callers" | API key is set but **the Generative Language API is not enabled** in the GCP project, OR the key has IP/app restrictions that block this endpoint |
| 400 | INVALID_ARGUMENT | "API key not valid" | Key is malformed, revoked, or from a different product (e.g. Maps key, OAuth client ID) |
| 429 | RESOURCE_EXHAUSTED | "Quota exceeded" | Free tier rate limit hit — wait or upgrade |
| 503 | UNAVAILABLE | "Service temporarily unavailable" | Google-side outage — retry with backoff |

**Key insight:** 403 ≠ invalid key. A 403 often means the key is valid but the API isn't enabled. Fix: enable the API at https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com

## Testing a Gemini API Key

```bash
# 1. Test key validity (models list — cheapest call)
curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=${KEY}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('models',[])), 'models') if 'models' in d else print('ERR:', d.get('error',{}).get('status',''), d.get('error',{}).get('message','')[:80])"

# 2. Test actual generation
curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${KEY}" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Say OK"}]}]}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('candidates',[{}])[0].get('content',{}).get('parts',[{}])[0].get('text',''); print('✅', c) if c else print('❌', d.get('error',{}).get('message','')[:80])"
```

**Note:** Gemini uses its own REST API format, NOT OpenAI-compatible `/v1/chat/completions`.
The key goes as a `?key=` query param, not an `Authorization: Bearer` header.

## Where the Key Lives

Hermes stores Gemini credentials in `~/.hermes/.env` as `GOOGLE_API_KEY`.
`GEMINI_API_KEY` is an alias (same value, different env var name).
After updating, restart gateway: `hermes gateway restart`

## Credential Pool Strategy

Config has `credential_pool_strategies.gemini: fill_first` — this means Hermes uses
the first available key and only falls back if it fails. Multiple keys can be added
for rotation (see credential-management.md).
