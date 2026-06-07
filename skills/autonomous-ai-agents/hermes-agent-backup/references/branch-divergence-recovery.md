# Branch Divergence Recovery

## Problem
If `git push origin main` succeeds but actual commits landed on a different branch (e.g. `master`), the remote `main` stays stale and the backup **appears to work but is actually empty**. This happens when:
- The repo was cloned/initialized with `master` as default but the push targets `main`
- A previous manual operation created a second branch

## Diagnosis
```bash
cd ~/hermes-setup
git branch -a -v          # check if HEAD/main != master
git log --all --oneline   # see which branch has the real commits
```

## Fix
```bash
git checkout main
git merge master --ff-only    # fast-forward to catch up
git push origin main
git branch -d master          # remove redundant branch
git push origin --delete master
```

## Prevention
After initial setup, always verify only ONE local branch exists and that it tracks `origin/main`:
```bash
git branch -a -v   # should show exactly: * main  <hash> ...  tracks origin/main
```

## Missing memory files on disk but present in git
If `~/.hermes/memory/USER.md` or other memory files vanish from disk (e.g. after a cleanup or agent error), they can often be recovered from the backup repo:
```bash
cd ~/hermes-setup
git show main:memory/USER.md > ~/.hermes/memory/USER.md
```
Always check `git ls-tree -r HEAD -- memory/` to see what the backup contains vs what's on disk.

## Post-fix verification checklist
1. `ls ~/.hermes/memory/` — MEMORY.md and USER.md exist
2. `cd ~/hermes-setup && git branch -a -v` — single branch, tracks origin/main
3. `git ls-tree -r HEAD -- memory/` — memory files present in HEAD
4. `git push origin main --dry-run` — push would succeed
5. `git status` — clean working tree
