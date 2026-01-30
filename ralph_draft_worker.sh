#!/usr/bin/env bash
set -euo pipefail

# Ralph Draft Worker - Uses AI to generate ONE draft per invocation
# This makes 1 AI call per run
# Runs every 10 minutes via cron (but rate limit enforces 3-min gap)

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

# Check rate limit
RATE_STATUS=$($GATEWAY check)
echo "Rate limit: $RATE_STATUS" | tee -a "$LOG_FILE"

if [[ "$RATE_STATUS" == WAIT:* ]]; then
    WAIT_SECONDS=${RATE_STATUS#WAIT:}
    echo "⏳ Cooldown active (${WAIT_SECONDS}s). Exiting." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Check draft queue
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
echo "Drafts in queue: $DRAFT_COUNT/5" | tee -a "$LOG_FILE"

if [[ "$DRAFT_COUNT" -ge 5 ]]; then
    echo "✅ Queue full. No work needed." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Determine persona (time-based rotation)
HOUR=$(date -u +"%H")
case "$HOUR" in
    00|01|02|03|04|05) PERSONA="insider" ;;
    06|07|08|09|10|11) PERSONA="analyst" ;;
    12|13|14|15|16|17) PERSONA="local" ;;
    *) PERSONA="insider" ;;
esac
echo "📝 Generating draft $((DRAFT_COUNT + 1))/5 as $PERSONA..." | tee -a "$LOG_FILE"

# Record API call
$GATEWAY record

# AI Draft Generation
AIDER_CMD="aider --model vertex_ai/gemini-2.0-flash-exp --no-auto-commits --no-show-model-warnings --yes-always --exit"

cat > /tmp/draft_prompt.txt << 'PROMPT'
You are Ralph, the SB60 Blog's content engine. Create ONE publication-ready draft.

INPUTS TO READ:
1. .ralph/research_summary.json - AI-analyzed trends and angles
2. .ralph/trends.json - Raw trending topics  
3. .ralph/real_intel.json - Verified news
4. personas.json - Voice/style for the active persona
5. _posts/*.md - Recent posts (avoid duplication)

CREATE:
One draft in .ralph/drafts/ with filename: draft-YYYYMMDD-HHMM-{persona}-{slug}.md

CONTENT REQUIREMENTS:
- 400-600 words of original analysis
- Lead with a specific insight from research
- Reference real data/trends where relevant
- Use the persona's voice (insider="sources say...", analyst="data shows...", local="you gotta check out...")
- NO AI words: additionally, moreover, furthermore, landscape, tapestry, delve
- NO filler phrases
- NO sign-offs at end

YAML frontmatter:
---
layout: post
title: "Specific, compelling headline"
author: "Persona Name"
date: PLACEHOLDER
tags: [relevant, tags, here]
excerpt: "Hook sentence"
persona: {persona_slug}
status: draft
---

Respond: "DRAFT CREATED: {filename}"
PROMPT

FILES=".ralph/research_summary.json .ralph/trends.json .ralph/real_intel.json personas.json"
for f in $(ls -1 _posts/*.md 2>/dev/null | tail -5); do
    FILES="$FILES $f"
done

if $AIDER_CMD $FILES --message "$(cat /tmp/draft_prompt.txt)" 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Draft worker completed" | tee -a "$LOG_FILE"
    
    # Update state with new count
    NEW_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]')
    python3 << EOF
import json
import datetime

try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
except:
    state = {}

state['draftsInQueue'] = $NEW_COUNT
state['lastDraftAt'] = datetime.datetime.utcnow().isoformat() + 'Z'

with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
print(f"State updated: {NEW_COUNT} drafts")
EOF
else
    echo "⚠️ Draft generation had issues" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
