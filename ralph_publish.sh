#!/usr/bin/env bash
set -euo pipefail

# Ralph Publish Job - Publishes one draft every 6 hours
# Triggered by cron, evaluates and publishes best draft

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/publish.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"

echo "=== Ralph Publish Job ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

cd "$REPO_DIR"

# Check if we have drafts
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
echo "Drafts available: $DRAFT_COUNT" | tee -a "$LOG_FILE"

if [[ "$DRAFT_COUNT" -eq 0 ]]; then
    echo "⚠️ No drafts to publish!" | tee -a "$LOG_FILE"
    # Send alert to Discord/webhook here if configured
    echo "" | tee -a "$LOG_FILE"
    exit 1
fi

# Determine persona for this publish slot
HOUR=$(date -u +"%H")
case "$HOUR" in
    00|01|02|03|04|05) TARGET_PERSONA="insider" ;;
    06|07|08|09|10|11) TARGET_PERSONA="analyst" ;;
    12|13|14|15|16|17) TARGET_PERSONA="local" ;;
    *) TARGET_PERSONA="insider" ;;
esac
echo "Target persona for this slot: $TARGET_PERSONA" | tee -a "$LOG_FILE"

# Check rate limit for humanization/polish
RATE_STATUS=$($GATEWAY check)
if [[ "$RATE_STATUS" == ALLOW ]]; then
    echo "🎯 Rate limit clear. Running evaluate_and_publish with humanization..." | tee -a "$LOG_FILE"
    $GATEWAY record
    python3 "$SCRIPT_DIR/evaluate_and_publish.py" --persona "$TARGET_PERSONA" 2>&1 | tee -a "$LOG_FILE"
else
    echo "⚡ Rate limit active ($RATE_STATUS). Running publish without humanization..." | tee -a "$LOG_FILE"
    # Fallback: publish best draft without AI polish
    python3 "$SCRIPT_DIR/publish_simple.py" --persona "$TARGET_PERSONA" 2>&1 | tee -a "$LOG_FILE" || true
fi

# Pull, build, commit, push
echo "Building and deploying..." | tee -a "$LOG_FILE"
git pull origin main 2>&1 | tee -a "$LOG_FILE" || true

if bundle exec jekyll build 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Jekyll build successful" | tee -a "$LOG_FILE"
    
    git add _posts/ data/ .ralph/
    git commit -m "publish: Scheduled post - $(date -u +"%H:%M UTC")" 2>&1 | tee -a "$LOG_FILE" || true
    git push origin main 2>&1 | tee -a "$LOG_FILE"
    echo "✅ Published and pushed!" | tee -a "$LOG_FILE"
else
    echo "❌ Jekyll build failed" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
