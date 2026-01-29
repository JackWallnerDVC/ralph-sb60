# AGENTS.md - SB60 Blog Loop Instructions

## Project Context
Building a published, sustainable SB60 blog with personas and automated updates.

## Ralph Loop

### How it works
The Ralph loop (`ralph_loop.sh`) runs iterative planning cycles:
1. Reads specs from `specs/` directory
2. Reads current `IMPLEMENTATION_PLAN.md`
3. Uses clawdbot agent to analyze and update the plan
4. Stops when `STATUS: COMPLETE` is found in the plan

### Running the loop
```bash
cd /Users/jackwallner/clawd/ralph-sb60
./ralph_loop.sh
```

### Configuration
- Uses `aider` with Vertex AI Gemini 3 Pro
- Requires `VERTEXAI_PROJECT` and `VERTEXAI_LOCATION` env vars (aider-specific)
- Model: `vertex_ai/gemini-3-pro-preview`
- Max iterations: 10

### Manual iteration with aider
If you need to run a single iteration manually:
```bash
cd /Users/jackwallner/clawd/ralph-sb60
export VERTEXAI_PROJECT=project-f1f026e2-b264-4c46-9e1
export VERTEXAI_LOCATION=global
aider --model vertex_ai/gemini-3-pro-preview --no-auto-commits --no-show-model-warnings --message "$(cat PROMPT.md)"
```

### Using clawdbot instead (alternative)
```bash
export GOOGLE_CLOUD_PROJECT=project-f1f026e2-b264-4c46-9e1
export GOOGLE_CLOUD_LOCATION=global
clawdbot agent --local --agent main --message "$(cat PROMPT.md)"
```

## Backpressure Commands
- `git status`
- `ls -R`

## Operational Learnings
- Using `aider` with Gemini 3 Pro via Vertex AI.
- Targeting free hosting (GitHub Pages/Vercel).
- Loop stops when `STATUS: COMPLETE` is added to IMPLEMENTATION_PLAN.md.
