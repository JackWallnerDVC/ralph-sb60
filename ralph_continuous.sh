#!/usr/bin/env bash
set -euo pipefail

# Ralph Continuous Mode
# Always-on research and drafting engine
# Runs continuously, preparing content for scheduled publishes

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
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

echo "=== Ralph Continuous Mode Started ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"
echo "Drafts dir: $DRAFTS_DIR" | tee -a "$LOG_FILE"
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
    ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l || echo "0"
}

# Function to get next publish time
get_next_publish() {
    local hour=$(date -u +"%H" | sed 's/^0//')
    local next_hour
    
    if [ "$hour" -lt 6 ]; then
        next_hour="00:00"
    elif [ "$hour" -lt 12 ]; then
        next_hour="06:00"
    elif [ "$hour" -lt 18 ]; then
        next_hour="12:00"
    else
        next_hour="18:00"
    fi
    
    echo "$(date -u +"%Y-%m-%d")T$next_hour:00+00:00"
}

# Function to get current persona based on time
get_current_persona() {
    local hour=$(date -u +"%H")
    case "$hour" in
        00|01|02|03|04|05) echo "insider" ;;
        06|07|08|09|10|11) echo "analyst" ;;
        12|13|14|15|16|17) echo "local" ;;
        *) echo "insider" ;;  # 18-23 rotates but default to insider
    esac
}

# Main continuous loop
iteration=0
while true; do
    iteration=$((iteration + 1))
    drafts_count=$(count_drafts)
    current_persona=$(get_current_persona)
    next_publish=$(get_next_publish)
    
    echo "--- Iteration $iteration ($(date -u +"%H:%M:%S UTC")) ---" | tee -a "$LOG_FILE"
    echo "Drafts in queue: $drafts_count" | tee -a "$LOG_FILE"
    echo "Current persona: $current_persona" | tee -a "$LOG_FILE"
    echo "Next publish: $next_publish" | tee -a "$LOG_FILE"
    
    # Update state
    update_state "lastActivity" "\"$(date -u +"%Y-%m-%dT%H:%M:%S%z")\""
    update_state "draftsInQueue" "$drafts_count"
    update_state "nextPublish" "\"$next_publish\""
    update_state "currentPersona" "\"$current_persona\""
    
    # Check if we need more drafts (keep 3-5 drafts ready)
    if [ "$drafts_count" -lt 3 ]; then
        echo "Draft queue low ($drafts_count). Generating new draft..." | tee -a "$LOG_FILE"
        
        # Create prompt for research/drafting
        cat > /tmp/ralph_draft_prompt.txt << 'PROMPT'
You are Ralph, the SB60 Blog's always-on content engine.

CURRENT TASK: Research and draft a new blog post for the queue.

1. Read the current state in .ralph/state.json to understand:
   - Which persona is currently active
   - What topics have been covered recently
   - What research topics are pending

2. Read personas.json to understand the voice/style of the active persona

3. Research current SB60 intel:
   - Check _posts/ for recently published topics (avoid duplicates)
   - Look at the research topics in state.json
   - Consider what's trending in SB60 news

4. Create a draft post in .ralph/drafts/ with:
   - Filename format: draft-YYYYMMDD-HHMM-{persona}-{slug}.md
   - Complete YAML frontmatter (title, author, date placeholder, tags, excerpt)
   - Full draft content (300-500 words)
   - Ready to polish and publish

5. Update .ralph/state.json:
   - Add the draft filename to a drafts list
   - Update researchTopics with new ideas
   - Update lastActivity timestamp

RULES:
- Each draft should be publication-ready quality
- Rotate through different angles/topics
- Keep persona voice consistent
- Don't publish - just draft for the queue
- If drafts directory has 5+ files, skip this iteration

COMPLETION: After creating the draft, respond with "DRAFT QUEUED: {filename}"
PROMPT

        # Build file context
        FILES="personas.json .ralph/state.json _posts/"
        
        # Run aider to generate draft
        if $AIDER_CMD $FILES --message "$(cat /tmp/ralph_draft_prompt.txt)" 2>&1 | tee -a "$LOG_FILE"; then
            echo "✅ Draft generation completed" | tee -a "$LOG_FILE"
        else
            echo "⚠️ Draft generation had issues" | tee -a "$LOG_FILE"
        fi
        
    else
        echo "Draft queue healthy ($drafts_count drafts). Monitoring..." | tee -a "$LOG_FILE"
    fi
    
    # Log activity
    echo "Iteration complete. Sleeping..." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Sleep for 15 minutes between iterations
    # This gives Ralph time to do research but doesn't hammer the API
    sleep 900
done
