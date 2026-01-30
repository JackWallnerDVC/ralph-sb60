#!/usr/bin/env bash
# Monitor that GitHub Pages is receiving updates
# Run this via cron: */30 * * * *

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
LOG_FILE="$REPO_DIR/.ralph/monitor.log"
WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"  # Optional: set in env

cd "$REPO_DIR"

# Check last local commit
LOCAL_COMMIT=$(git rev-parse HEAD)

# Check last remote commit  
git fetch origin main --quiet 2>/dev/null
REMOTE_COMMIT=$(git rev-parse origin/main)

# Check GitHub Pages deployment
PAGES_SHA=$(curl -sf https://api.github.com/repos/JackWallnerDVC/ralph-sb60/pages | jq -r '.source.commit // "unknown"' 2>/dev/null || echo "unknown")

if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
    echo "$(date): ⚠️ Unpushed commits detected!" >> "$LOG_FILE"
    git push origin main >> "$LOG_FILE" 2>&1
fi

# Alert if Pages hasn't updated in 2+ hours
if [[ -n "$WEBHOOK_URL" ]]; then
    LAST_PUSH=$(git log -1 --format=%ct origin/main)
    NOW=$(date +%s)
    HOURS_SINCE=$(( (NOW - LAST_PUSH) / 3600 ))
    
    if [[ $HOURS_SINCE -gt 2 ]]; then
        curl -s -X POST -H "Content-Type: application/json" \
            -d '{"embeds":[{"title":"🚨 Ralph Alert","description":"No publishes in '$HOURS_SINCE' hours. Check draft queue.","color":15158332}]}' \
            "$WEBHOOK_URL" > /dev/null
    fi
fi
