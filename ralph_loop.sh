#!/usr/bin/env bash
set -euo pipefail

# Ralph Loop for SB60 Blog
MAX_ITERS=10
PLAN_SENTINEL='STATUS: COMPLETE'
LOG_FILE=".ralph/ralph.log"
mkdir -p .ralph

# Export required Vertex AI environment variables for aider
# These are REQUIRED for vertex_ai/ models to work
export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"

# Also set Google Cloud vars for compatibility
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-$VERTEXAI_PROJECT}"
export GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-$VERTEXAI_LOCATION}"

# Ensure git identity is set (required for aider)
git config user.name "Ralph SB60" 2>/dev/null || true
git config user.email "ralph@sb60-intel.github.io" 2>/dev/null || true

cd /Users/jackwallner/clawd/ralph-sb60

# Build file list for aider context
# Include all relevant files so aider can do gap analysis
FILES_TO_ADD=""
[[ -f IMPLEMENTATION_PLAN.md ]] && FILES_TO_ADD="$FILES_TO_ADD IMPLEMENTATION_PLAN.md"
[[ -f PROMPT.md ]] && FILES_TO_ADD="$FILES_TO_ADD PROMPT.md"
[[ -f personas.json ]] && FILES_TO_ADD="$FILES_TO_ADD personas.json"
[[ -f _config.yml ]] && FILES_TO_ADD="$FILES_TO_ADD _config.yml"
[[ -d specs ]] && FILES_TO_ADD="$FILES_TO_ADD specs/"
[[ -d _layouts ]] && FILES_TO_ADD="$FILES_TO_ADD _layouts/"
[[ -d _posts ]] && FILES_TO_ADD="$FILES_TO_ADD _posts/"

# Aider command with Gemini 3 Pro via Vertex AI
# --exit: Exit after processing message (don't enter interactive mode)
# --no-auto-commits: Don't auto-commit changes
# --no-show-model-warnings: Skip model warning prompts
# --yes-always: Auto-answer yes to prompts
CLI_CMD="aider --model vertex_ai/gemini-3-pro-preview --no-auto-commits --no-show-model-warnings --yes-always --exit"

for i in $(seq 1 "$MAX_ITERS"); do
  echo -e "\n=== Ralph iteration $i/$MAX_ITERS ===" | tee -a "$LOG_FILE"
  echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"
  echo "Files: $FILES_TO_ADD" | tee -a "$LOG_FILE"

  # Run aider with files and message
  # Files are passed as arguments, message via --message
  if $CLI_CMD $FILES_TO_ADD --message "$(cat PROMPT.md)" 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Iteration $i completed successfully" | tee -a "$LOG_FILE"
  else
    echo "⚠️ Iteration $i had issues, continuing..." | tee -a "$LOG_FILE"
  fi

  # Check for completion in IMPLEMENTATION_PLAN.md
  if [[ -f IMPLEMENTATION_PLAN.md ]] && grep -Fq "$PLAN_SENTINEL" IMPLEMENTATION_PLAN.md; then
    echo "✅ Planning Phase Complete." | tee -a "$LOG_FILE"
    exit 0
  fi
  
  # Small delay between iterations to avoid rate limits
  sleep 2
done

echo "❌ Max iterations reached." | tee -a "$LOG_FILE"
exit 1
