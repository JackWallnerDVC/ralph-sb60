#!/usr/bin/env bash
set -euo pipefail

# Ralph Continuous Mode - Viral Edition
# LOCK FILE: Prevents concurrent execution with other Ralph scripts (macOS compatible)

LOCK_FILE="/tmp/ralph.lock"
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$LOCK_PID" ] && ps -p "$LOCK_PID" >/dev/null 2>&1; then
        echo "$(date): Another Ralph process (PID $LOCK_PID) is running. Exiting." >&2
        exit 1
    fi
fi
echo $$ > "$LOCK_FILE"

# Cleanup lock on exit
trap 'rm -f "$LOCK_FILE"' EXIT
# Always-on research, drafting, and publishing engine
# When drafts hit 5, picks best, humanizes, and publishes immediately

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/continuous.log"
STATE_FILE="$REPO_DIR/.ralph/state.json"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"
mkdir -p "$DRAFTS_DIR"

# Export Vertex AI env vars
export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-$VERTEXAI_PROJECT}"
export GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-$VERTEXAI_LOCATION}"

# Git identity
git config --global user.name "Ralph SB60" 2>/dev/null || true
git config --global user.email "ralph@sb60-intel.github.io" 2>/dev/null || true

cd "$REPO_DIR"

echo "=== Ralph Continuous Mode (Viral) Started ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"
echo "Mode: Generate → Evaluate → Humanize → Publish" | tee -a "$LOG_FILE"
echo "Trigger: When 5 drafts are ready" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Aider base command
AIDER_CMD="aider --model vertex_ai/gemini-3-pro-preview --no-auto-commits --no-show-model-warnings --yes-always --exit"

# Function to update state file
update_state() {
    local key="$1"
    local value="$2"
    python3 << EOF
import json
with open("$STATE_FILE", 'r') as f:
    state = json.load(f)
state["$key"] = $value
with open("$STATE_FILE", 'w') as f:
    json.dump(state, f, indent=2)
EOF
}

# Function to count drafts
count_drafts() {
    local count=0
    if ls "$DRAFTS_DIR"/draft-*.md 1>/dev/null 2>&1; then
        count=$(ls -1 "$DRAFTS_DIR"/draft-*.md | wc -l | tr -d '[:space:]')
    fi
    echo "$count"
}

# Function to get trending topics for virality
fetch_trends() {
    echo "Fetching X/Twitter trends..." | tee -a "$LOG_FILE"
    python3 "$SCRIPT_DIR/get_trends.py" >> "$LOG_FILE" 2>&1 || true
}

# Function to evaluate and publish when we have 5 drafts
evaluate_and_publish() {
    echo "🎯 Queue full (5 drafts). Evaluating for virality..." | tee -a "$LOG_FILE"
    
    python3 "$SCRIPT_DIR/evaluate_and_publish.py" 2>&1 | tee -a "$LOG_FILE"
    
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        echo "✅ Publish cycle complete" | tee -a "$LOG_FILE"
    else
        echo "⚠️ Publish had issues (exit $exit_code)" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
}

# Function to get current persona based on time (for drafting context)
get_current_persona() {
    local hour=$(date -u +"%H")
    case "$hour" in
        00|01|02|03|04|05) echo "insider" ;;
        06|07|08|09|10|11) echo "analyst" ;;
        12|13|14|15|16|17) echo "local" ;;
        *) echo "insider" ;;  # 18-23
    esac
}

# Main continuous loop
iteration=0
while true; do
    iteration=$((iteration + 1))
    drafts_count=$(count_drafts)
    current_persona=$(get_current_persona)
    
    echo "--- Iteration $iteration ($(date -u +"%H:%M:%S UTC")) ---" | tee -a "$LOG_FILE"
    echo "Drafts in queue: $drafts_count/5" | tee -a "$LOG_FILE"
    echo "Current persona focus: $current_persona" | tee -a "$LOG_FILE"
    
    # Update state
    update_state "lastActivity" "\"$(date -u +"%Y-%m-%dT%H:%M:%S%z")\""
    update_state "draftsInQueue" "$drafts_count"
    update_state "currentPersona" "\"$current_persona\""
    
    # Check if we have 5 drafts - if so, evaluate and publish
    if [ "$drafts_count" -ge 5 ]; then
        evaluate_and_publish
        # After publishing, drafts are cleared - continue to generate more
        drafts_count=$(count_drafts)
    fi
    
    # Generate drafts until we have 5
    if [ "$drafts_count" -lt 5 ]; then
        echo "📢 Generating viral draft ($((drafts_count + 1))/5)..." | tee -a "$LOG_FILE"
        
        # Fetch fresh trends before drafting
        fetch_trends
        
        # Create prompt for viral research/drafting
        cat > /tmp/ralph_draft_prompt.txt << 'PROMPT'
You are Ralph, the SB60 Blog's content engine.

CURRENT TASK: Research trending SB60 topics and draft a LEGITIMATE, IN-DEPTH blog post.

GOAL: Create high-value content rooted in truth and specific detail. Avoid "surface bullshit" and fluff.
- LEGITIMACY: Information must be grounded in actual NFL developments, stadium logistics, or verified Bay Area trends.
- DEPTH: Dig into the "how" and "why". Don't just say what's happening; explain the mechanics behind it.
- NO FANTASY: Do not invent fake "sources" or imaginary events. Base topics on trends.json or real-world intel.

1. Read the current state in .ralph/state.json
2. Read .ralph/trends.json to see what's trending.
3. Read personas.json for voice guidance (Sarah, Marcus, or Tony).
4. Check _posts/ for recently published topics (AVOID DUPLICATES).

5. Research/Synthesize SB60 intel:
   - Specific details: Names, numbers, technical specs, dollar amounts, exact dates.
   - Professional tone: Even if the persona is "casual", the information should be high-quality and reliable.

6. Create a draft post in .ralph/drafts/:
   - Filename: draft-YYYYMMDD-HHMM-{persona}-{slug}.md
   - Hook title: Informative and compelling, but NOT clickbait.
   - Opening: Lead with a specific fact or observation.
   - Body: 400-600 words of dense, valuable information.
   - NO SIGN-OFFS: Do not include "— The Insider" or similar tags at the end.
   - NO SCHEDULE MENTIONS: Do not mention posting frequency or automated schedules.
   - Full YAML frontmatter with a professional excerpt.

7. Update .ralph/state.json with the new draft info

CONTENT RULES:
- Lead with value, not background fluff.
- Use specific numbers and entities (e.g., "The NFL’s G-4 loan program" vs "league funding").
- NO AI words: additionally, moreover, furthermore, underscores, landscape, tapestry, delve, foster.
- NO filler: "It is important to note", "In order to", "Due to the fact that".

COMPLETION: After creating the draft, respond with "DRAFT QUEUED: {filename}"
PROMPT

        # Build file context
        FILES="personas.json .ralph/state.json .ralph/trends.json"
        # Add recent post files (up to 3) for context
        for f in $(ls -1 _posts/*.md 2>/dev/null | tail -3); do
            FILES="$FILES $f"
        done
        
        # Run aider to generate draft
        if $AIDER_CMD $FILES --message "$(cat /tmp/ralph_draft_prompt.txt)" 2>&1 | tee -a "$LOG_FILE"; then
            echo "✅ Draft generation completed" | tee -a "$LOG_FILE"
        else
            echo "⚠️ Draft generation had issues" | tee -a "$LOG_FILE"
        fi
        
    else
        echo "Queue healthy ($drafts_count drafts). Waiting for publish..." | tee -a "$LOG_FILE"
    fi
    
    # Log activity
    echo "Iteration complete. Sleeping..." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Check every 10 minutes (reduced frequency to avoid rate limits)
    sleep 600
done
