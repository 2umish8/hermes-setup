---
name: cron-job-execution-constraints
description: Strategies for executing automated tasks in a cron job environment, particularly when programmatic tools like `execute_code` are restricted or unavailable.
category: devops
---
# Cron Job Execution Constraints

When running as a cron job, the `execute_code` tool (and potentially others that involve arbitrary code execution or subprocess calls) may be blocked by default for security reasons. This prevents complex, multi-step logic that would normally be implemented using Python scripts.

## Problem: Restricted Execution Environments

When running as a cron job, the `execute_code` tool (and potentially others that involve arbitrary code execution or subprocess calls) may be blocked by default for security reasons. This prevents complex, multi-step logic that would normally be implemented using Python scripts.

## Solution: Fallback Strategies

When direct programmatic execution is unavailable, adapt by:


### 1. Leveraging Terminal Commands

Utilize the `terminal` tool for executing shell commands. This is often the primary method for tasks that can be achieved through shell scripting and standard Unix utilities.

**Example: CPU Monitoring in Cron Context**

When running as a cron job, `execute_code` can be blocked, necessitating the use of `terminal` commands. For instance, to monitor CPU spikes and log details:

1.  **Check CPU usage:** Use `top -bn1 | grep "%Cpu(s)" | awk '{print 100 - $NF}' | bc -l` to get the current CPU percentage.
2.  **Conditional logging:** If usage exceeds a threshold (e.g., 300%), wait for a short period (e.g., 2 minutes) to confirm the spike. If it remains high, capture system logs (`journalctl --since "10 minutes ago"`) and top processes (`ps aux --sort=-%cpu | head -n 5`) by redirecting their output to a timestamped log file.
3.  **Notification:** Construct and print a consolidated alert message.

This approach encapsulates the logic within a shell script executed via `terminal`, avoiding the need for `execute_code`.

### 2. Simplifying Logic

If the original task had complex conditional branching or sequential operations, assess if these can be simplified to a series of independent `terminal` calls, or if the alerting/logging mechanism can be handled by external cron capabilities (e.g., redirecting output to files, using `mail` if available).

### 3. Acknowledging Limitations

Be transparent with the user about what can and cannot be achieved due to environmental constraints. If a task critically depends on `execute_code` or other restricted tools, explain the blocker and offer the closest possible alternative.

### 2. Simplifying Logic

If the original task had complex conditional branching or sequential operations, assess if these can be simplified to a series of independent `terminal` calls, or if the alerting/logging mechanism can be handled by external cron capabilities (e.g., redirecting output to files, using `mail` if available).

### 3. Acknowledging Limitations

Be transparent with the user about what can and cannot be achieved due to environmental constraints. If a task critically depends on `execute_code` or other restricted tools, explain the blocker and offer the closest possible alternative.

## Pitfalls

*   **`execute_code` Blocked:** In cron job contexts, `execute_code` often requires explicit approval or configuration (`approvals.cron_mode`) to run. Without it, it will be blocked, returning an error.
*   **Silent Failures:** When using `terminal` for background processes, always ensure proper notification mechanisms (`notify_on_complete=True`) or polling (`process(action='poll')`) are used. Unmonitored background processes can lead to silent task failures.
*   **Command Availability:** Not all shell commands might be available or behave identically compared to an interactive session. Always verify commands if possible.

## When to update this skill:
*   When you encounter `execute_code` being blocked in a cron job context.
*   When you successfully implement a system monitoring or automation task using only `terminal` commands due to restrictions.
*   When the user asks for automation in an environment where `execute_code` might be restricted.
