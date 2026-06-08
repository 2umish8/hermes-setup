---
name: schedule-cron-job
description: How to schedule a script via cron.
category: devops
---

# Schedule a Script via Cron

## Overview
This skill explains how to add a cron entry that runs a script on a regular schedule. It covers user‑level and system‑level cron, absolute paths, running scripts manually, and common pitfalls.

## Usage
1. Put your script in a writable location, e.g., `/home/hermes/.hermes/scripts/your-script.sh`.
2. Make it executable:
   ```bash
   chmod +x /home/hermes/.hermes/scripts/your-script.sh
   ```
3. Add a cron line:
   * **User crontab** (current user):
     ```bash
     crontab -l | (cat; echo "* * * * * hermes /home/hermes/.hermes/scripts/your-script.sh >> /dev/null 2>&1") | crontab -
     ```
   * **System crontab** (`/etc/cron.d/your_job` – requires sudo):
     ```bash
     echo "* * * * * hermes /home/hermes/.hermes/scripts/your-script.sh >> /dev/null 2>&1" | sudo tee /etc/cron.d/your_job
     ```
4. Verify with `crontab -l` or `grep` in `/etc/cron.d/`.
5. Ensure the script runs correctly when executed manually before scheduling.

## Key Tips
- Use **absolute paths** for scripts.
- Redirect **stdout and stderr** (`>> /dev/null 2>&1`) unless you want mail alerts.
- Test the script first to catch errors.
- Adjust the cron timing fields for your desired schedule.

## Common Pitfalls
- Avoid ambiguous redirect errors when piping crontab commands. Use braces `{}` or a temporary file to combine output.
- Ensure portability: prefer user crontab for per‑user jobs.
- Validate the script manually before scheduling.
- Redirect both stdout and stderr to avoid mail alerts.
- If using system crontab, set the correct user field.
- Include dependencies: `journalctl` must be installed.

1. Forgetting `chmod +x`.
2. Using a relative path in the cron entry.
3. Missing `2>&1` and causing cron to send emails.
4. Running commands that need elevated privileges without proper `sudo` setup.

## References
- `man 5 crontab` – cron syntax.
- `/etc/cron.d/` – system cron directory.
- `cron.allow` / `cron.deny` – user permission controls.
