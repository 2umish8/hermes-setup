# Groq Model Reference (May 2026)

## Production Models (Free Tier)

| Model ID | Speed (t/s) | Price/1M tokens | Rate Limits (Dev Plan) | Context |
|---|---|---|---|---|
| llama-3.1-8b-instant | 560 | $0.05 in / $0.08 out | 250K TPM, 1K RPM | 131K |
| llama-3.3-70b-versatile | 280 | $0.59 in / $0.79 out | 300K TPM, 1K RPM | 131K |
| openai/gpt-oss-120b | 500 | $0.15 in / $0.60 out | 250K TPM, 1K RPM | 131K |
| openai/gpt-oss-20b | 1000 | $0.075 in / $0.30 out | 250K TPM, 1K RPM | 131K |

## Preview Models

| Model ID | Speed (t/s) | Price/1M tokens | Rate Limits | Context |
|---|---|---|---|---|
| meta-llama/llama-4-scout-17b-16e-instruct | 750 | $0.11 in / $0.34 out | 300K TPM, 1K RPM | 131K |
| qwen/qwen3-32b | 400 | $0.29 in / $0.59 out | 300K TPM, 1K RPM | 131K |

Prices shown are for paid tier. Free tier is $0 but rate-limited.

## API Details
- Base URL: https://api.groq.com/openai/v1
- OpenAI-compatible endpoint
- API key prefix: `gsk_`
- Error 1010 = invalid/expired key
- Docs: https://console.groq.com/docs/models