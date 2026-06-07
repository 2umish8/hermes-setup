---
name: hermes-agent-backup
description: "Backup Hermes configuration, skills, memory, and cron jobs to a Git repository."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, backup, configuration, git]
    homepage: https://github.com/NousResearch/hermes-agent
---

# Hermes Backup Skill

This skill provides a set of shell commands and recommendations for backing up your Hermes installation and Git repository. It is intended to be run on a scheduled cron job or manually by a system administrator.

## Prerequisites

* `rsync` for efficient file synchronization.
* `git` installed and an origin remote configured.
* User running the backup has `~/.hermes` writable and has pull/push access to the target repo.

## Typical Usage

```
# 1. Copy files
rsync -av --delete --exclude='.git/' --exclude='*.log' ~/.hermes/skills/ /home/hermes/hermes-setup/skills/
rsync -av --delete --exclude='.git/' ~/.hermes/memory/ /home/hermes/hermes-setup/memory/
rsync -av --delete --exclude='.git/' ~/.hermes/cron/   /home/hermes/hermes-setup/cron/
cp ~/.hermes/config.yaml /home/hermes/hermes-setup/config/

# 2. Commit and push
cd /home/hermes/hermes-setup
 git add .
 if ! git diff-index --quiet HEAD --; then
   git commit -m "Automated backup: $(date)"
   git push origin main
 fi
```

## Tips & Common Errors

* **Memory directory** – The correct path is `~/.hermes/memory/` (not `.memories`). If you see error `rsync: [sender] change_dir "~/.hermes/memories" failed`, this typo is the cause.
* **Exclude `.git`** – Prevent backing up the repository history to avoid infinite recursion.
* **Large logs** – Excluding `*.log` prevents huge files from bloating the backup.
* **Permission issues** – Ensure the backup user has read/write rights on the target directory and execute rights on the git repository.
* **Git remote** – Verify `git remote -v` points to the correct repository. If `origin` does not exist, run `git remote add origin <url>`.
* **Cron environment** – Environment variables are often limited; set `HOME`, `SSH_AGENT_PID`, `SSH_AUTH_SOCK`, and any required API keys explicitly in the cron job.

## Extending the Skill

The skill is intentionally simple so it can be incorporated into your own automation scripts. You can extend the `rsync` commands to include additional directories or adjust the patterns as your project evolves.

## Reference

- [Reference: backup.md](references/backup.md)
