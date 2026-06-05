---
name: user-reminders
description: Personal reminder list for Mischael — architectural decisions and tasks to track. Only load when user asks about reminders, todos, or says "rappelle-moi", "mes notes", "qu'est-ce que je dois faire". This skill is NOT auto-loaded in normal sessions.
version: 1.1.0
---

# User Reminders (Mischael)

Pending items the user wants to track. Hermes does NOT execute these — they are the user's personal backlog.

## Model Quirks

- [ ] **Gemini Flash hallucinates changes** — prétend avoir modifié des fichiers sans le faire, ou annonce des changements qui n'existent pas. Toujours vérifier l'état réel après une action Gemini Flash.

## Architectural Decisions

- [ ] Setup 7 dev agents + cooperation mechanism
- [ ] Provider rotation & auto-switching for Hermes (credential pools)
- [ ] Accountability system: task entry points + intelligent reminders
- [ ] Multi-gateway evaluation: separate Telegram bots per agent/role

---

## Usage
- User says "rappelle-moi X" → add item here
- User says "montre mes rappels" → load this skill
- User says "j'ai fait X" → mark as done or remove

## Smart Recall Routing

See [references/smart-recall.md](references/smart-recall.md) for the full routing convention.

### Critical Pitfall: Never Mix User Reminders with Agent Execution Todos

The agent's `todo` tool is for HERMES' execution tasks ONLY. User reminders (things the
user wants to be reminded of, not things for Hermes to do) must go to THIS skill, never to
the agent's todo list. Mixing them forces the user to verbally separate them,
wasting tokens and causing confusion.

Same rule for `memory`: memory is for durable facts/preferences injected into every turn.
Do not bloat it with reminder lists — that's what this skill is for.