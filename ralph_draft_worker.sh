#!/usr/bin/env bash
set -euo pipefail

# Ensure PATH includes local bin for aider
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH:/usr/local/bin:$HOME/.nvm/versions/node/v22.22.0/bin"

# Ralph Draft Worker - MULTI-AI content generation
# Generates ONE high-quality draft using 3 AI calls (research, outline, write)

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/draft_worker.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"

export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"

mkdir -p "$DRAFTS_DIR"
cd "$REPO_DIR"

echo "=== Ralph Draft Worker (Multi-AI) ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

# Check queue
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
echo "Drafts in queue: $DRAFT_COUNT/5" | tee -a "$LOG_FILE"

if [[ "$DRAFT_COUNT" -ge 5 ]]; then
    echo "✅ Queue full. Exiting." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Determine persona
HOUR=$(date -u +"%H")
case "$HOUR" in
    00|01|02|03|04|05) PERSONA="insider" ;;
    06|07|08|09|10|11) PERSONA="analyst" ;;
    12|13|14|15|16|17) PERSONA="local" ;;
    *) PERSONA="insider" ;;
esac

echo "📝 Generating draft $((DRAFT_COUNT + 1))/5 as $PERSONA" | tee -a "$LOG_FILE"

AIDER_CMD="aider --model vertex_ai/gemini-2.0-flash-exp --no-auto-commits --no-show-model-warnings --yes-always --exit"
RESEARCH_FILES=".ralph/research_summary.json .ralph/angle_${PERSONA}.json .ralph/trends.json personas.json"
for f in $(ls -1 _posts/*.md 2>/dev/null | tail -5); do
    RESEARCH_FILES="$RESEARCH_FILES $f"
done

# AI Call 1: Deep research on specific angle
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 1/3: Deep research..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record
$AIDER_CMD $RESEARCH_FILES --message "Read research_summary.json and angle_${PERSONA}.json. Select the BEST angle for ${PERSONA} persona. Create .ralph/deep_research.json with: specific facts to include, sources to cite (real or 'sources say'), key quotes/stats, counter-arguments to address, related topics for context." 2>&1 | tee -a "$LOG_FILE"

# AI Call 2: Create detailed outline
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 2/3: Creating outline..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record
$AIDER_CMD $RESEARCH_FILES .ralph/deep_research.json --message "Using deep_research.json, create .ralph/outline.json with: hook (first sentence), 5 section titles with key points per section, specific stats/facts for each section, transition sentences between sections. Target 500-600 words total." 2>&1 | tee -a "$LOG_FILE"

# AI Call 3: Write the full draft
echo "" | tee -a "$LOG_FILE"
echo "🧠 AI Call 3/3: Writing draft..." | tee -a "$LOG_FILE"
$GATEWAY wait
$GATEWAY record

TIMESTAMP=$(date -u +"%Y%m%d-%H%M")
SLUG=$(python3 -c "import json; d=json.load(open('.ralph/deep_research.json')); print(d.get('slug','topic'))" 2>/dev/null || echo "topic")
FILENAME="draft-${TIMESTAMP}-${PERSONA}-${SLUG}.md"

$AIDER_CMD $RESEARCH_FILES .ralph/deep_research.json .ralph/outline.json --message "Write the complete draft post as ${FILENAME} in .ralph/drafts/. Use outline.json structure. Include YAML frontmatter: layout, title, author (from personas.json), date: PLACEHOLDER, tags, excerpt, persona, status: draft. Write 500-600 words. Use ${PERSONA} voice. NO AI words (additionally, moreover, furthermore, landscape, tapestry, delve). NO sign-offs. Specific details only." 2>&1 | tee -a "$LOG_FILE"

# Update state
NEW_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]')
python3 << EOF 2>&1 | tee -a "$LOG_FILE"
import json
import datetime

try:
    with open('.ralph/state.json', 'r') as f:
        state = json.load(f)
except:
    state = {}

state['draftsInQueue'] = $NEW_COUNT
state['lastDraftAt'] = datetime.datetime.utcnow().isoformat() + 'Z'

with open('.ralph/state.json', 'w') as f:
    json.dump(state, f, indent=2)

print(f"✅ Draft worker complete: {NEW_COUNT} drafts in queue")
EOF

echo "" | tee -a "$LOG_FILE"
