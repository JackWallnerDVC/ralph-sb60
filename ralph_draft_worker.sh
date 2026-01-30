#!/usr/bin/env bash
set -euo pipefail

# Ralph Draft Worker - Generates ONE draft per invocation
# This is the ONLY script that calls the AI API
# Exits after one draft, letting cron control spacing

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/draft_worker.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"
STATE_FILE="$REPO_DIR/.ralph/state.json"

# Export Vertex AI env vars
export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"

mkdir -p "$DRAFTS_DIR"
cd "$REPO_DIR"

echo "=== Ralph Draft Worker ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

# Check rate limit first
RATE_STATUS=$($GATEWAY check)
echo "Rate limit status: $RATE_STATUS" | tee -a "$LOG_FILE"

if [[ "$RATE_STATUS" == WAIT:* ]]; then
    WAIT_SECONDS=${RATE_STATUS#WAIT:}
    echo "⏳ Rate limit cooldown active. Wait ${WAIT_SECONDS}s. Exiting." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Check if we need more drafts
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]')
echo "Current drafts: $DRAFT_COUNT" | tee -a "$LOG_FILE"

if [[ "$DRAFT_COUNT" -ge 5 ]]; then
    echo "✅ Draft queue full ($DRAFT_COUNT/5). No work needed." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Record that we're about to use the API
$GATEWAY record
echo "📝 Generating draft $((DRAFT_COUNT + 1))/5..." | tee -a "$LOG_FILE"

# Get current persona based on time
HOUR=$(date -u +"%H")
case "$HOUR" in
    00|01|02|03|04|05) PERSONA="insider" ;;
    06|07|08|09|10|11) PERSONA="analyst" ;;
    12|13|14|15|16|17) PERSONA="local" ;;
    *) PERSONA="insider" ;;
esac
echo "Using persona: $PERSONA" | tee -a "$LOG_FILE"

# Build prompt
cat > /tmp/ralph_single_draft_prompt.txt << 'PROMPT'
You are Ralph, the SB60 Blog's content engine.

TASK: Create ONE high-quality draft post.

1. Read .ralph/state.json for current context
2. Read .ralph/trends.json for trending topics
3. Read personas.json for the active persona voice
4. Check _posts/ for recent topics (avoid duplicates)

5. Create ONE draft in .ralph/drafts/:
   - Filename: draft-YYYYMMDD-HHMM-{persona}-{slug}.md
   - 400-600 words, specific details, no AI words
   - NO sign-offs, NO schedule mentions
   - Full YAML frontmatter

6. Update .ralph/state.json with new draft info

CONTENT RULES:
- Lead with value
- Specific names, numbers, dollar amounts
- NO: additionally, moreover, furthermore, landscape, tapestry, delve
- NO: "It is important to note", "In order to"

Respond with: "DRAFT CREATED: {filename}"
PROMPT

# Run aider to generate single draft
AIDER_CMD="aider --model vertex_ai/gemini-2.0-flash-exp --no-auto-commits --no-show-model-warnings --yes-always --exit"
FILES="personas.json .ralph/state.json .ralph/trends.json"

# Add recent posts for context
for f in $(ls -1 _posts/*.md 2>/dev/null | tail -3); do
    FILES="$FILES $f"
done

echo "Calling AI API..." | tee -a "$LOG_FILE"
if $AIDER_CMD $FILES --message "$(cat /tmp/ralph_single_draft_prompt.txt)" 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Draft worker completed" | tee -a "$LOG_FILE"
    
    # Update state with draft count
    NEW_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]')
    python3 << EOF
import json
try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
except:
    state = {}
state['draftsInQueue'] = $NEW_COUNT
state['lastDraftAt'] = '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
EOF
else
    echo "⚠️ Draft generation had issues" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
