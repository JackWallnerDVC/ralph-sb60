#!/usr/bin/env bash
set -euo pipefail

# Ralph Research Job - Gathers data AND uses AI to analyze/summarize
# Runs every 15 minutes via cron
# Makes 1 AI call per run (summarizing trends/intel)

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/research.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"
TRENDS_FILE="$REPO_DIR/.ralph/trends.json"
INTEL_FILE="$REPO_DIR/.ralph/real_intel.json"

# Export Vertex AI env vars
export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"

cd "$REPO_DIR"

echo "=== Ralph Research Job ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

# Check rate limit
RATE_STATUS=$($GATEWAY check)
echo "Rate limit: $RATE_STATUS" | tee -a "$LOG_FILE"

if [[ "$RATE_STATUS" == WAIT:* ]]; then
    WAIT_SECONDS=${RATE_STATUS#WAIT:}
    echo "⏳ Cooldown active (${WAIT_SECONDS}s). Skipping AI analysis." | tee -a "$LOG_FILE"
    # Still fetch raw data even if we can't analyze
    echo "Fetching raw trends/intel only..." | tee -a "$LOG_FILE"
    python3 "$SCRIPT_DIR/get_trends.py" --no-ai 2>&1 | tee -a "$LOG_FILE" || true
    python3 "$SCRIPT_DIR/fetch_intel.py" 2>&1 | tee -a "$LOG_FILE" || true
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Step 1: Fetch raw data (no API calls)
echo "🔍 Fetching raw trends and intel..." | tee -a "$LOG_FILE"
python3 "$SCRIPT_DIR/get_trends.py" --no-ai 2>&1 | tee -a "$LOG_FILE" || true
python3 "$SCRIPT_DIR/fetch_intel.py" 2>&1 | tee -a "$LOG_FILE" || true

# Step 2: AI Analysis - record the call
$GATEWAY record
echo "🧠 Analyzing trends with AI..." | tee -a "$LOG_FILE"

# Use aider to analyze and create research summary
AIDER_CMD="aider --model vertex_ai/gemini-2.0-flash-exp --no-auto-commits --no-show-model-warnings --yes-always --exit"

cat > /tmp/research_prompt.txt << 'PROMPT'
You are Ralph's research analyst. Your job is to find the angles.

1. Read .ralph/trends.json - raw trending topics
2. Read .ralph/real_intel.json - verified news from official sources
3. Read _posts/ for context on what's already been covered

ANALYZE and CREATE:
Create .ralph/research_summary.json with:
{
  "hotTopics": ["topic1", "topic2", "topic3"],
  "angles": {
    "insider": "specific operational angle from intel",
    "analyst": "data/stats angle from trends", 
    "local": "Bay Area experience angle"
  },
  "keywords": ["keyword1", "keyword2"],
  "urgency": "high/medium/low",
  "tweetInsights": "What people are actually saying on X"
}

Rules:
- Extract REAL insights from the data provided
- Identify what each persona should focus on
- Note any contradictions between official intel and social chatter
- Suggest specific article angles, not generic topics

Respond: "RESEARCH COMPLETE: {key finding}"
PROMPT

FILES=".ralph/trends.json .ralph/real_intel.json personas.json"
for f in $(ls -1 _posts/*.md 2>/dev/null | tail -5); do
    FILES="$FILES $f"
done

if $AIDER_CMD $FILES --message "$(cat /tmp/research_prompt.txt)" 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Research analysis complete" | tee -a "$LOG_FILE"
    
    # Update state
    python3 << EOF
import json
import datetime

try:
    with open('.ralph/state.json', 'r') as f:
        state = json.load(f)
except:
    state = {}

state['lastResearch'] = datetime.datetime.utcnow().isoformat() + 'Z'
state['researchAnalyzed'] = True

with open('.ralph/state.json', 'w') as f:
    json.dump(state, f, indent=2)
print("State updated")
EOF
else
    echo "⚠️ AI analysis had issues" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
