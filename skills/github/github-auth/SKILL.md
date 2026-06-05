---
name: github-auth
description: "GitHub auth setup: HTTPS tokens, SSH keys, gh CLI login."
version: 1.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [GitHub, Authentication, Git, gh-cli, SSH, Setup]
    related_skills: [github-pr-workflow, github-code-review, github-issues, github-repo-management]
---

# GitHub Authentication Setup

To interact with GitHub, we need to configure your identity and authentication.

## Workflow: Multi-Identity Commits

To separate your manual actions from agent actions in the git history:

1. **Your Identity (Main):** Configure globally:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your-email@example.com"
   ```

2. **Agent Identity (Bot):** Configure locally in the project repository:
   ```bash
   git config --local user.name "Hermes Agent"
   git config --local user.email "hermes-agent@noreply.github.com"
   ```
   This ensures my commits are tagged as 'Hermes Agent' in your history.

---

To interact with GitHub, we need to configure your identity and authentication. Since `gh` CLI isn't installed, we'll use HTTPS tokens.


## Step 1: Create a Personal Access Token

Go to: **https://github.com/settings/tokens**

- Click "Generate new token (classic)"
- Give it a name like "hermes-agent"
- Select these scopes:
  - `repo` (Full repository access)
  - `workflow` (Trigger actions)
  - `read:org` (Optional, if using org repos)
- Click "Generate" and **copy the token** immediately.

## Step 2: Configure your identity

Please provide the following so I can configure your git profile:
1. Your full name (for commits)
2. Your email address (for commits)
3. Your GitHub username

## Step 3: Set up authentication

Once you give me your details, I will:
1. Configure `git` to use your name and email.
2. Configure `git` to use a credential helper to store your token.
3. Help you perform the first login to save your token.
