#!/usr/bin/env bash
set -euo pipefail

# Ralph Research Job - Fetches intel WITHOUT using AI APIs
# Runs every 15 minutes via cron
# Just gathers data, doesn't generate content

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/research.log"
TRENDS_FILE="$REPO_DIR/.ralph/trends.json"
INTEL_FILE="$REPO_DIR/.ralph/real_intel.json"

echo "=== Ralph Research Job ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

# Fetch X/Twitter trends (no API calls to Vertex)
echo "Fetching trends..." | tee -a "$LOG_FILE"
python3 "$SCRIPT_DIR/get_trends.py" 2>&1 | tee -a "$LOG_FILE" || true

# Fetch real intel from news sources (no API calls)
echo "Fetching real intel..." | tee -a "$LOG_FILE"
python3 "$SCRIPT_DIR/fetch_intel.py" 2>&1 | tee -a "$LOG_FILE" || true

# Update state with research timestamp
python3 << EOF 2>&1 | tee -a "$LOG_FILE"
import json
import datetime

state_file = "$REPO_DIR/.ralph/state.json"
try:
    with open(state_file, 'r') as f:
        state = json.load(f)
except:
    state = {}

state['lastResearch'] = datetime.datetime.utcnow().isoformat() + 'Z'
state['trendsAvailable'] = True

with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)

print(f"Research complete: {state['lastResearch']}")
EOF

echo "Research job complete." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
