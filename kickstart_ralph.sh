#!/usr/bin/env bash
# Kickstart Ralph - Ensures job-based architecture is healthy
# Runs every 5 minutes via cron

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
cd "$REPO_DIR"

LOG_FILE="$REPO_DIR/.ralph/kickstart.log"
TIMESTAMP=$(date "+%a %b %d %H:%M:%S %Z %Y")

# Make sure scripts are executable
chmod +x ralph_research.sh ralph_draft_worker.sh ralph_publish.sh 2>/dev/null || true
chmod +x .ralph/rate_limit_gateway.sh 2>/dev/null || true

# Check draft queue status
DRAFT_COUNT=$(ls -1 .ralph/drafts/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")

# Check rate limit status
RATE_STATUS=$(.ralph/rate_limit_gateway.sh status 2>/dev/null || echo "UNKNOWN")

echo "$TIMESTAMP: Ralph healthy | Drafts: $DRAFT_COUNT | Rate: $RATE_STATUS" >> "$LOG_FILE"

# If drafts are critically low (< 2), we could alert or trigger emergency mode
if [[ "$DRAFT_COUNT" -lt 2 ]]; then
    echo "$TIMESTAMP: ⚠️ LOW DRAFT ALERT: $DRAFT_COUNT drafts" >> "$LOG_FILE"
fi
