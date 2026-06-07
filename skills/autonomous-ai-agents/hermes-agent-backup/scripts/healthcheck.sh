#!/bin/bash
# Post-fix verification for hermes-setup backup repo
# Run after any backup troubleshooting to confirm everything is healthy
set -euo pipefail

REPO="${1:-$HOME/hermes-setup}"
PASS=0
FAIL=0

check() {
    if eval "$2" >/dev/null 2>&1; then
        echo "✅ $1"
        ((PASS++))
    else
        echo "❌ $1"
        ((FAIL++))
    fi
}

echo "=== Backup Health Check: $REPO ==="
echo ""

check "MEMORY.md exists on disk" "test -f $HOME/.hermes/memory/MEMORY.md"
check "USER.md exists on disk" "test -f $HOME/.hermes/memory/USER.md"
check "Single branch (no master/main split)" "[ \$(cd $REPO && git branch | wc -l) -eq 1 ]"
check "HEAD tracks origin/main" "cd $REPO && git rev-parse HEAD = git rev-parse origin/main"
check "Memory files in HEAD" "cd $REPO && git ls-tree HEAD -- memory/MEMORY.md | grep -q blob"
check "Working tree clean" "cd $REPO && git diff-index --quiet HEAD --"
check "Push would succeed" "cd $REPO && git push origin main --dry-run 2>&1 | grep -q 'Everything up-to-date\|-> main'"

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && echo "🎉 All checks passed" || echo "⚠️  Some checks failed — investigate above"
