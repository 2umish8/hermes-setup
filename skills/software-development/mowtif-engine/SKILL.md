---
name: mowtif-engine
description: "Workflow and architectural governance for the Mowtif productivity monorepo (Turborepo)."
---

# Mowtif-Engine Skill

This skill governs all interactions with the Mowtif productivity ecosystem. Use this to ensure architectural consistency, branching policies, and structured task execution.

## Architectural Principles
- **Branching Policy:** Never commit to `main`. All work happens on feature branches, merged via PRs into `dev`.
- **Workflow:** Use `writing-plans` to outline changes before code execution.
- **Kanban:** All non-trivial work must be tracked in the project Kanban.
- **Governance:** Use `requesting-code-review` for PRs to `dev`.

## Workflow
1. **Plan:** Before any coding, execute `writing-plans` to create a `plan.md` in `.hermes/plans/`.
2. **Execute:** Run tasks via `subagent-driven-development` to keep the main conversation clean.
3. **Verify:** Use `test-driven-development` and the `requesting-code-review` skill.

## Pitfalls
- **Environment:** Always verify Turbo configuration in `turbo.json` before triggering builds.
- **Service Persistence:** Many apps in the monorepo lack persistent supervision (systemd/PM2). If an app is unreachable, verify the process is running; if not, suggest configuring systemd to avoid recurrent outages.
- **Ambiguity:** If a requirement is unclear, do not proceed; use `clarify` to ask the Architect for details.
