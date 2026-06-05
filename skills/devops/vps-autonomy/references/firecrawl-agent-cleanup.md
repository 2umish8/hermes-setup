# Firecrawl Agent Cleanup (May 2026)

Firecrawl `init --all` installed skills for ALL detected agents. On this VPS, only **Hermes** and **OpenHands** are valid.

## Valid Agents (Keep)

| Agent | Path | Status |
|-------|------|--------|
| Hermes | `~/.hermes/` | Active (this session) |
| OpenHands | `~/.openhands/` | Active |

## Invalid Agents (Deleted May 29)

Firecrawl created empty `skills/` dirs with firecrawl symlinks in these. All deleted:

- `.claude/`
- `.codeartsdoer/`
- `.codebuddy/`
- `.codeium/`
- `.codemaker/`
- `.codestudio/`
- `.commandcode/`
- `.kilocode/`
- `.zencoder/`

## Prevention

Firecrawl install command patched from `--all` to `--agent hermes --agent openhands` in both skill files:

- `~/.hermes/skills/devops/firecrawl/SKILL.md`
- `~/.hermes/skills/firecrawl/rules/install.md`

## Source of Truth

`.agents/skills/` holds the actual 29 firecrawl skill files. Both `.hermes/skills/firecrawl*` and `.openhands/skills/firecrawl*` are symlinks to `../../.agents/skills/firecrawl*`.