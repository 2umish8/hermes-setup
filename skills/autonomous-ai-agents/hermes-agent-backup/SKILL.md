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

```bash
# 1. Copy files
rsync -av --delete --exclude='.git/' --exclude='*.log' ~/.hermes/skills/ /home/hermes/hermes-setup/skills/
rsync -av --delete --exclude='.git/' ~/.hermes/memory/ /home/hermes/hermes-setup/memory/
rsync -av --delete --exclude='.git/' ~/.hermes/cron/   /home/hermes/hermes-setup/cron/
cp ~/.hermes/config.yaml /home/hermes/hermes-setup/config/

# 2. Commit and push
cd /home/hermes/hermes-setup

# Add all changes
git add .

# Commit if there are changes
if ! git diff-index --quiet HEAD --;
  git commit -m "Automated backup: $(date)"
  git push origin main
fi
```

## Tips & Common Errors

* **Memory directory path**: The correct path is `~/.hermes/memory/`. If you encounter an `rsync` error like `rsync: [sender] change_dir "~/.hermes/memories" failed`, ensure the source path in your rsync command is correctly set to `~/.hermes/memory/` and that the directory exists.
* **Exclude `.git`**: Prevent backing up the repository history to avoid infinite recursion.
* **Large logs**: Excluding `*.log` prevents huge files from bloating the backup.
* **Permission issues**: Ensure the backup user has read/write rights on the target directory and execute rights on the git repository.
* **Git remote**: Verify `git remote -v` points to the correct repository. If `origin` does not exist, run `git remote add origin <url>`.
* **Cron environment**: Environment variables are often limited; set `HOME`, `SSH_AGENT_PID`, `SSH_AUTH_SOCK`, and any required API keys explicitly in the cron job.
* **Branch divergence**: If backup appears to work but remote is empty, check `git branch -a -v` — commits may be on `master` while push targets `main`. See [references/branch-divergence-recovery.md](references/branch-divergence-recovery.md) for full recovery steps.
* **Missing memory files**: If `USER.md` or `MEMORY.md` vanish from disk, recover from git: `cd ~/hermes-setup && git show main:memory/USER.md > ~/.hermes/memory/USER.md`

## Post-fix Verification
Run the healthcheck script after any backup troubleshooting:
```bash
bash ~/.hermes/skills/autonomous-ai-agents/hermes-agent-backup/scripts/healthcheck.sh
```
See [scripts/healthcheck.sh](scripts/healthcheck.sh).

## Extending the Skill

The skill is intentionally simple so it can be incorporated into your own automation scripts. You can extend the `rsync` commands to include additional directories or adjust the patterns as your project evolves.

## References

- [Branch Divergence Recovery](references/branch-divergence-recovery.md)
