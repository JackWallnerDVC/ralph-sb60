#!/usr/bin/env bash
set -euo pipefail

# Ensure PATH includes local bin for aider
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH:/usr/local/bin:$HOME/.nvm/versions/node/v22.22.0/bin"

# Ralph Publish Job - Evaluates drafts and publishes the best one
# Uses AI to humanize/polish if rate limit allows
# Trigger: Called when draft queue reaches threshold (5 drafts)

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/publish.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"

echo "=== Ralph Publish Job ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(TZ=America/Los_Angeles date +"%Y-%m-%dT%H:%M:%S %Z")" | tee -a "$LOG_FILE"

cd "$REPO_DIR"

# Check draft count
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
echo "Drafts available: $DRAFT_COUNT" | tee -a "$LOG_FILE"

if [[ "$DRAFT_COUNT" -eq 0 ]]; then
    echo "⚠️ No drafts to publish!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 1
fi

# Pick persona based on which has fewest posts
PERSONA_FILE="$REPO_DIR/data/published.json"
if [[ -f "$PERSONA_FILE" ]]; then
    INSIDER=$(python3 -c "import json; d=json.load(open('$PERSONA_FILE')); print(d.get('stats',{}).get('postsByPersona',{}).get('insider',0))")
    ANALYST=$(python3 -c "import json; d=json.load(open('$PERSONA_FILE')); print(d.get('stats',{}).get('postsByPersona',{}).get('analyst',0))")
    LOCAL=$(python3 -c "import json; d=json.load(open('$PERSONA_FILE')); print(d.get('stats',{}).get('postsByPersona',{}).get('local',0))")
    
    # Find minimum
    if [[ $INSIDER -le $ANALYST && $INSIDER -le $LOCAL ]]; then
        TARGET_PERSONA="insider"
    elif [[ $ANALYST -le $LOCAL ]]; then
        TARGET_PERSONA="analyst"
    else
        TARGET_PERSONA="local"
    fi
else
    TARGET_PERSONA="insider"
fi
echo "Target persona: $TARGET_PERSONA (balancing distribution)" | tee -a "$LOG_FILE"

# Check rate limit for optional humanization
RATE_STATUS=$($GATEWAY check)
if [[ "$RATE_STATUS" == ALLOW && "$DRAFT_COUNT" -ge 2 ]]; then
    # Plenty of drafts and rate limit clear - use AI to evaluate and polish
    echo "🎯 Rate limit clear. Using AI to evaluate and humanize..." | tee -a "$LOG_FILE"
    $GATEWAY record
    
    # Run evaluate_and_publish which uses AI
    /Library/Frameworks/Python.framework/Versions/3.8/bin/python3 "$SCRIPT_DIR/evaluate_and_publish.py" --persona "$TARGET_PERSONA" 2>&1 | tee -a "$LOG_FILE"
else
    if [[ "$RATE_STATUS" == WAIT:* ]]; then
        echo "⏳ Rate limit active. Publishing best draft without AI polish..." | tee -a "$LOG_FILE"
    else
        echo "📰 Only 1 draft. Publishing without AI polish to preserve it..." | tee -a "$LOG_FILE"
    fi
    
    # Fallback: simple publish without AI
    python3 "$SCRIPT_DIR/publish_simple.py" --persona "$TARGET_PERSONA" 2>&1 | tee -a "$LOG_FILE" || true
fi

# Build and deploy
echo "🏗️ Building site..." | tee -a "$LOG_FILE"
git pull origin main 2>&1 | tee -a "$LOG_FILE" || true

# Try local build, but GitHub Pages will build on push anyway
if command -v bundle >/dev/null 2>&1 && bundle exec jekyll build 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Local build successful" | tee -a "$LOG_FILE"
else
    echo "⚠️ Local build skipped (GitHub Pages will build on push)" | tee -a "$LOG_FILE"
fi

# Always commit and push - GitHub Pages handles the actual build
git add _posts/ data/ .ralph/
git commit -m "publish: Draft queue threshold - $(TZ=America/Los_Angeles date +"%-I:%M %p %Z")" 2>&1 | tee -a "$LOG_FILE" || true
git push origin main 2>&1 | tee -a "$LOG_FILE"
echo "✅ Published and deployed!" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
