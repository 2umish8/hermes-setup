---
name: cooperative-ai-coding
description: Use external agentic CLIs (Antigravity CLI, GitHub Copilot CLI, Claude Code) to delegate or accelerate complex coding tasks. This skill configures the exact hierarchy, prioritization rules, and non-interactive command flags for execution.
version: 1.0.0
---

# Cooperative AI Coding

This skill enables Hermes to collaborate with external AI coding agents installed in the terminal environment. By delegating complex, multi-file, or highly intensive tasks to these specialized CLIs, Hermes can accelerate your workflow and run multiple agentic processes in parallel.

---

## 🚨 CRITICAL PRIORITIZATION HIERARCHY

To optimize subscription costs and leverage your annual licenses, you must strictly follow this priority order when choosing which CLI to launch:

### 1. 🥇 Primary Choice: Antigravity CLI (`agy`)
*   **Status:** Annual Subscription (Prioritized)
*   **Best For:** Workspace-wide tasks, deep research, architectural analysis, structured plans, and asynchronous background workflows.
*   **When to use:** Use `agy` as your first choice for almost all complex developer tasks.

### 2. 🥈 Secondary Choice: GitHub Copilot CLI (`copilot`)
*   **Status:** Annual Subscription (Secondary)
*   **Best For:** Direct code editing, translation between programming languages, Git workflow assistance, shell syntax translation, and fast logic.
*   **When to use:** Use `copilot` if `agy` is busy, is not suited for the quick shell-editing task, or if you specifically need GitHub ecosystem features.

### 3. 🥉 Last Resort: Claude Code (`claude`)
*   **Status:** Pay-as-you-go / Limited (Last Resort)
*   **Best For:** Uniquely complex logic or specific scenarios where other models struggle.
*   **When to use:** Use `claude` **ONLY** as a last resort when both `agy` and `copilot` have failed to resolve the issue, or when the user explicitly requests it.

---

## 🛠️ CLI INVOCATION SYNTAX (NON-INTERACTIVE / AUTONOMOUS)

When executing tasks autonomously on behalf of the user, run the CLI tools with **full-approval flags** so they do not block on permission prompts.

### 1. Executing Antigravity CLI (`agy`)
To run a single prompt autonomously and capture the output:
```bash
agy -p "Your prompt here" --dangerously-skip-permissions
```
*   `-p` or `--print` tells the CLI to execute a single prompt non-interactively and output the response.
*   `--dangerously-skip-permissions` auto-approves all filesystem and terminal operations so the execution does not hang.

### 2. Executing GitHub Copilot CLI (`copilot`)
To run a single prompt autonomously and capture the output:
```bash
copilot -p "Your prompt here" --yolo
```
*   `-p` or `--prompt` runs the query non-interactively.
*   `--yolo` (or `--allow-all-tools`) grants full permissions for file modifications and terminal runs.

### 3. Executing Claude Code (`claude`)
To run a single prompt autonomously and capture the output:
```bash
claude -p "Your prompt here" --permission-mode bypassPermissions
```
*   `-p` or `--print` runs the agent in non-interactive print mode.
*   `--permission-mode bypassPermissions` allows the agent to edit files and run commands without pausing for prompts.

---

## 💬 INTERACTIVE Handovers

If a task requires the user to interactively pair-program with the external agent, Hermes can spin up an interactive terminal session using the following commands:
- **Antigravity CLI:** `agy -i "Initial task description"`
- **GitHub Copilot CLI:** `copilot -i "Initial task description"`
- **Claude Code:** `claude` (or with optional arguments)

---

## 💡 EXAMPLE DELEGATION PATTERNS

### Example 1: Asking Antigravity CLI to refactor code (Primary Choice)
```bash
agy -p "Refactor the auth controller in projects/Mowtif/packages/auth/index.js to use JWT instead of sessions" --dangerously-skip-permissions
```

### Example 2: Asking Copilot to write unit tests (Secondary Choice)
```bash
copilot -p "Write unit tests for the functions in projects/Mowtif/packages/utils.js using Jest" --yolo
```

### Example 3: Falling back to Claude Code (Last Resort Only)
```bash
claude -p "Fix the memory leak in projects/Mowtif/apps/web/server.js" --permission-mode bypassPermissions
```

---

## 🔄 CRITICAL GIT SYNCHRONIZATION RULES (VPS ACTIVE WORKSPACE)

Since this VPS serves as your active development workspace where Hermes and secondary agents code:

1. **Pull Before Start (Up-to-Date Baseline)**:
   * **Mandatory Rule**: Before launching *any* coding task or delegating a task to `agy`, `copilot`, or `claude`, Hermes **MUST** pull the latest changes from GitHub to ensure the workspace is completely up-to-date with your local changes.
   * **Action**:
     ```bash
     git pull origin <current-branch>
     ```

2. **Push On Complete (Sync Back to GitHub)**:
   * **Mandatory Rule**: Once a feature, task, or bugfix is completed, built, and verified by the linter/tests, Hermes **MUST** commit and push the changes back to GitHub.
   * **Action**:
     ```bash
     git add .
     git commit -m "feat(hermes): <brief description of accomplishments>"
     git push origin <current-branch>
     ```

