#!/usr/bin/env bash
set -euo pipefail

# LOCK FILE: Prevents concurrent execution (macOS compatible)
LOCK_FILE="/tmp/ralph_publish.lock"
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$LOCK_PID" ] && ps -p "$LOCK_PID" >/dev/null 2>&1; then
        echo "$(TZ=America/Los_Angeles date): Publish already in progress (PID $LOCK_PID). Exiting." >&2
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Ralph Threshold Publish - Only publishes when draft queue is full
# Trigger: Called by cron every 5 minutes, but only acts when drafts >= 5

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/publish.log"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"

# Ensure PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH:/usr/local/bin:$HOME/.nvm/versions/node/v22.22.0/bin"

cd "$REPO_DIR"

# Count drafts
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")

# Only proceed if we have 5+ drafts
if [[ "$DRAFT_COUNT" -lt 5 ]]; then
    # Silent exit - no spam logs
    exit 0
fi

echo "=== Ralph Threshold Publish Triggered ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(TZ=America/Los_Angeles date +"%Y-%m-%dT%H:%M:%S %Z")" | tee -a "$LOG_FILE"
echo "Drafts in queue: $DRAFT_COUNT (threshold: 5)" | tee -a "$LOG_FILE"

# Pick persona based on which has fewest posts (balancing distribution)
PERSONA_FILE="$REPO_DIR/data/published.json"
if [[ -f "$PERSONA_FILE" ]]; then
    INSIDER=$(python3 -c "import json; d=json.load(open('$PERSONA_FILE')); print(d.get('stats',{}).get('postsByPersona',{}).get('insider',0))" 2>/dev/null || echo "0")
    ANALYST=$(python3 -c "import json; d=json.load(open('$PERSONA_FILE')); print(d.get('stats',{}).get('postsByPersona',{}).get('analyst',0))" 2>/dev/null || echo "0")
    LOCAL=$(python3 -c "import json; d=json.load(open('$PERSONA_FILE')); print(d.get('stats',{}).get('postsByPersona',{}).get('local',0))" 2>/dev/null || echo "0")
    
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

# Run evaluate_and_publish (handles virality scoring, humanization, git push)
echo "🎯 Running evaluate_and_publish..." | tee -a "$LOG_FILE"
python3 "$SCRIPT_DIR/evaluate_and_publish.py" 2>&1 | tee -a "$LOG_FILE"

echo "✅ Publish cycle complete at $(TZ=America/Los_Angeles date +"%-I:%M %p %Z")" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
