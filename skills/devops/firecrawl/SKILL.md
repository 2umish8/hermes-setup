---
name: firecrawl
description: "Skills and tools for Firecrawl web extraction and automation."
version: 1.0.0
---

# Firecrawl

Firecrawl provides reliable web context with strong search, scraping, and interaction tools.

## Install
```bash
npx -y firecrawl-cli@latest init --agent hermes --agent openhands --browser
```

## Usage Paths

### Path A: Live Web Tools (In-Session)
Use when you need web data during your work:
- Search: `firecrawl search "query"`
- Scrape: `firecrawl scrape "url"`
- Interact: `firecrawl interact "url"` (for pages needing clicks/forms)
- Map/Crawl: `firecrawl map "url"`, `firecrawl crawl "url"`
- Diagnose failures: `firecrawl ask <jobId>`

### Path B: App Integration (Build)
Use when integrating Firecrawl into application code:
- Store API key: `dotenv FIRECRAWL_API_KEY=fc-...`
- Build skills: `firecrawl-build`, `firecrawl-build-scrape`, `firecrawl-build-search`

### Path C: Workflows
Use for finished artifacts (research, SEO, etc.):
- Start with `firecrawl-workflows` to route to specific research/QA tasks.

### Path D: Auth
If you need an API key:
1. Run browser auth flow.
2. Poll status.
3. Save key to `.env`.

### Path E: REST API
Endpoint: `https://api.firecrawl.dev/v2`
Auth: `Authorization: Bearer fc-YOUR_API_KEY`
Endpoints: `/search`, `/scrape`, `/interact`, `/support/ask`, `/support/docs-search`
