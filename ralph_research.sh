#!/usr/bin/env bash
set -euo pipefail

# Ralph Research Job - MULTI-AI analysis pipeline
# Runs every 15 minutes, uses 3-4 AI calls spaced 10s apart

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/research.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"

export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"

cd "$REPO_DIR"

echo "=== Ralph Research Job (Multi-AI) ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

# Step 1: Fetch raw data (no AI)
echo "🔍 Fetching raw data..." | tee -a "$LOG_FILE"
python3 "$SCRIPT_DIR/get_trends.py" --no-ai 2>&1 | tee -a "$LOG_FILE" || true
python3 "$SCRIPT_DIR/fetch_intel.py" 2>&1 | tee -a "$LOG_FILE" || true

AIDER_CMD="aider --model vertex_ai/gemini-2.0-flash-exp --no-auto-commits --no-show-model-warnings --yes-always --exit"
FILES=".ralph/trends.json .ralph/real_intel.json personas.json"
for f in $(ls -1 _posts/*.md 2>/dev/null | tail -3); do
    FILES="$FILES $f"
done

# AI Call 1: Analyze trends and extract key topics
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 1/4: Analyzing trends..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record
$AIDER_CMD $FILES --message "Analyze .ralph/trends.json and .ralph/real_intel.json. Create .ralph/analysis_1_topics.json with: top 5 trending topics, their momentum (rising/falling), and which persona each fits best. Be specific with names, teams, events." 2>&1 | tee -a "$LOG_FILE"

# AI Call 2: Deep dive on insider angles
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 2/4: Insider angles..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record
$AIDER_CMD $FILES .ralph/analysis_1_topics.json --message "For insider persona: Based on analysis_1_topics.json, create .ralph/angle_insider.json with: 3 specific operational angles, behind-scenes details, sources-style hooks, exclusive-feel headlines. Focus on logistics, security, stadium ops, team movements." 2>&1 | tee -a "$LOG_FILE"

# AI Call 3: Deep dive on analyst angles  
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 3/4: Analyst angles..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record
$AIDER_CMD $FILES .ralph/analysis_1_topics.json --message "For analyst persona: Based on analysis_1_topics.json, create .ralph/angle_analyst.json with: 3 data-driven angles, specific stats to research, betting/market insights, numbers-heavy hooks. Focus on odds, trends, historical patterns, prop bet value." 2>&1 | tee -a "$LOG_FILE"

# AI Call 4: Deep dive on local angles
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 4/4: Local angles..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record
$AIDER_CMD $FILES .ralph/analysis_1_topics.json --message "For local persona: Based on analysis_1_topics.json, create .ralph/angle_local.json with: 3 Bay Area experience angles, specific venues/restaurants/events, insider tips, fan-focused hooks. Focus on Santa Clara, transportation, food, tailgating." 2>&1 | tee -a "$LOG_FILE"

# Combine into final research summary
echo "" | tee -a "$LOG_FILE"
echo "📝 Compiling research summary..." | tee -a "$LOG_FILE"
python3 << EOF 2>&1 | tee -a "$LOG_FILE"
import json
import datetime

try:
    with open('.ralph/analysis_1_topics.json') as f:
        topics = json.load(f)
except:
    topics = {"topics": []}

try:
    with open('.ralph/angle_insider.json') as f:
        insider = json.load(f)
except:
    insider = {"angles": []}

try:
    with open('.ralph/angle_analyst.json') as f:
        analyst = json.load(f)
except:
    analyst = {"angles": []}

try:
    with open('.ralph/angle_local.json') as f:
        local = json.load(f)
except:
    local = {"angles": []}

summary = {
    "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
    "topics": topics,
    "angles_by_persona": {
        "insider": insider,
        "analyst": analyst,
        "local": local
    },
    "recommendations": {
        "priority": topics.get("top_topics", [{}])[0].get("topic", "general") if topics.get("top_topics") else "general",
        "urgency": "high" if topics.get("momentum") == "rising" else "medium"
    }
}

with open('.ralph/research_summary.json', 'w') as f:
    json.dump(summary, f, indent=2)

print(f"✅ Research complete: {len(topics.get('top_topics', []))} topics, {len(insider.get('angles', [])) + len(analyst.get('angles', [])) + len(local.get('angles', []))} angles")
EOF

echo "" | tee -a "$LOG_FILE"
