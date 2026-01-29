# Ralph Guide - SB60 Blog Automation

## Overview

**Ralph** is the autonomous content engine for the SB60 Blog. It operates at two levels:
1. **Development Mode**: The `ralph_loop.sh` script for building/updating the blog
2. **Production Mode**: The `sb60-blog` skill within clawdbot for 4x daily publishing

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        RALPH SYSTEM                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │  Ralph Loop  │     │  Clawdbot    │     │   GitHub     │    │
│  │  (aider)     │────▶│   Skill      │────▶│   Actions    │    │
│  │              │     │              │     │              │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│         │                    │                    │            │
│         ▼                    ▼                    ▼            │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   Source     │     │    _posts/   │     │   Live Site  │    │
│  │   (planning) │     │   (content)  │     │ (Pages)      │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Mode 1: Ralph Loop (Development)

### What It Does
- Runs aider with Gemini 3 Pro via Vertex AI
- Performs planning, gap analysis, and updates
- Iterates until `STATUS: COMPLETE` is found in IMPLEMENTATION_PLAN.md

### How to Run

```bash
cd /Users/jackwallner/clawd/ralph-sb60
./ralph_loop.sh
```

### How It Works

1. **Sets Environment Variables**
   - `VERTEXAI_PROJECT` and `VERTEXAI_LOCATION` for Vertex AI access
   - Git identity for aider commits

2. **Builds File Context**
   - Automatically includes relevant files:
     - `IMPLEMENTATION_PLAN.md` - The master plan
     - `PROMPT.md` - Current task instructions
     - `personas.json` - Content personas
     - `_config.yml` - Jekyll configuration
     - `specs/` - Specifications directory
     - `_layouts/` - Template files
     - `_posts/` - Existing posts

3. **Runs Aider Loop**
   - Up to 10 iterations
   - Each iteration sends context + prompt to Gemini 3 Pro
   - Checks for completion sentinel

### Configuration

Edit `ralph_loop.sh` to adjust:

| Variable | Default | Purpose |
|----------|---------|---------|
| `MAX_ITERS` | 10 | Maximum planning iterations |
| `PLAN_SENTINEL` | `STATUS: COMPLETE` | Completion trigger text |
| `VERTEXAI_PROJECT` | `project-f1f026e2-b264-4c46-9e1` | GCP project ID |
| `VERTEXAI_LOCATION` | `global` | Vertex AI region |

---

## Mode 2: Clawdbot Skill (Production)

### What It Does
- Runs 4x daily via cron (00:00, 06:00, 12:00, 18:00 UTC)
- Generates new blog posts using rotating personas
- Commits and pushes to trigger GitHub Pages deploy

### How to Enable

```bash
# Install the cron job
cd /Users/jackwallner/clawd/skills/sb60-blog/scripts
./setup_cron.sh

# Verify it's installed
crontab -l | grep sb60-blog
```

### Persona Rotation

| Time (UTC) | Persona | Voice |
|------------|---------|-------|
| 00:00 | Insider | Behind-the-scenes, exclusive |
| 06:00 | Analyst | Data-driven, objective |
| 12:00 | Local | Enthusiastic, experiential |
| 18:00 | Rotating | Cycles through all three |

### Manual Trigger

```bash
# Generate a post right now
cd /Users/jackwallner/clawd/skills/sb60-blog/scripts
./run_now.sh

# Or use clawdbot directly
cd /Users/jackwallner/clawd
echo "Run the sb60-blog skill." | clawdbot skill --local sb60-blog
```

---

## GitHub Actions (Auto-Deploy)

### Workflow

Located at: `.github/workflows/pages.yml`

**Triggers:**
- Push to `main` branch
- Manual dispatch (via GitHub UI)

**Process:**
1. Checkout code
2. Setup Ruby 3.2 + Bundler
3. Configure GitHub Pages
4. Build Jekyll site
5. Deploy to Pages

### Status Check

```bash
# Check recent runs
cd ralph-sb60
gh run list --workflow=pages.yml

# Or visit: https://github.com/jackwallner/ralph-sb60/actions
```

---

## How Ralph Works Within Clawdbot

### Component Flow

```
Cron (every 6h)
    │
    ▼
┌──────────────────┐
│  clawdbot skill  │── Loads: skills/sb60-blog/SKILL.md
│  sb60-blog       │
└──────────────────┘
    │
    ▼
┌──────────────────┐
│  Agent Loader    │── Loads: agents/sb60-blog-agent/AGENT.md
│  (get_agent.py)  │
└──────────────────┘
    │
    ▼
┌──────────────────┐
│  Ralph Agent     │── Generates content as persona
│  (Gemini 3 Pro)  │── Writes to: _posts/YYYY-MM-DD-*.md
└──────────────────┘
    │
    ▼
┌──────────────────┐
│  Git Operations  │── Commits + pushes to main
│  (publish.sh)    │
└──────────────────┘
    │
    ▼
┌──────────────────┐
│  GitHub Actions  │── Builds + deploys Jekyll
│  (pages.yml)     │── Publishes to: sb60-intel.github.io
└──────────────────┘
```

### State Tracking

```bash
# Check what's been published
cat /Users/jackwallner/clawd/ralph-sb60/data/published.json
```

Contains:
- `rotation`: Order of personas
- `currentIndex`: Next persona to publish
- `posts`: Array of published posts
- `stats`: Publishing statistics

---

## Adjusting Ralph

### 1. Change Publishing Frequency

Edit `skills/sb60-blog/scripts/setup_cron.sh`:

```bash
# Current: Every 6 hours (4x daily)
CRON_SCHEDULE="0 */6 * * *"

# Change to: Every 12 hours (2x daily)
CRON_SCHEDULE="0 */12 * * *"

# Change to: Daily at 9am
CRON_SCHEDULE="0 9 * * *"
```

Then reinstall:
```bash
./setup_cron.sh
```

### 2. Add/Change Personas

Edit `ralph-sb60/personas.json`:

```json
{
  "personas": [
    {
      "id": "new-persona",
      "name": "The Historian",
      "style": "Long-form, contextual, retrospective",
      "topics": [
        "Super Bowl history",
        "Levi's Stadium legacy",
        "Bay Area sports moments"
      ]
    }
  ]
}
```

Update rotation in `data/published.json`:
```json
{
  "rotation": ["insider", "analyst", "local", "historian"]
}
```

### 3. Change Model/AI Settings

Edit `ralph_loop.sh` for development:
```bash
# Current
CLI_CMD="aider --model vertex_ai/gemini-3-pro-preview ..."

# Change to Claude
CLI_CMD="aider --model anthropic/claude-3-5-sonnet-20241022 ..."
```

For production (clawdbot skill), edit the agent config or set via environment.

### 4. Modify Content Rules

Edit `agents/sb60-blog-agent/AGENT.md`:
- Update persona descriptions
- Change content rules
- Adjust word count or style guidelines

### 5. Add New File Types to Context

Edit `ralph_loop.sh` and add to `FILES_TO_ADD`:

```bash
[[ -f new-file.md ]] && FILES_TO_ADD="$FILES_TO_ADD new-file.md"
[[ -d new-directory ]] && FILES_TO_ADD="$FILES_TO_ADD new-directory/"
```

### 6. Change Completion Criteria

Edit `ralph_loop.sh`:
```bash
# Current
PLAN_SENTINEL='STATUS: COMPLETE'

# Custom
PLAN_SENTINEL='READY FOR DEPLOYMENT'
```

---

## Troubleshooting

### Ralph Loop Issues

| Symptom | Fix |
|---------|-----|
| "Please add files to chat" | Check that FILES_TO_ADD includes relevant files |
| Vertex AI 404 errors | Verify `VERTEXAI_PROJECT` and model access |
| Git identity errors | Script now auto-sets identity, or run manually: `git config user.name "..."` |
| Max iterations reached | Check IMPLEMENTATION_PLAN.md for completion status |

### Publishing Issues

| Symptom | Fix |
|---------|-----|
| Cron not running | Check `crontab -l`, verify clawdbot path |
| Posts not deploying | Check GitHub Actions status |
| Jekyll build fails | Run locally: `bundle exec jekyll build` |
| Rate limit errors | Wait 5 min, check Discord #errors channel |

### Useful Commands

```bash
# Check Ralph log
tail -f ralph-sb60/.ralph/ralph.log

# Check publish log
tail -f ralph-sb60/.ralph/publish.log

# Check cron log
tail -f skills/sb60-blog/cron.log

# Verify Jekyll builds
cd ralph-sb60 && bundle exec jekyll build

# Check what's scheduled
crontab -l
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `ralph_loop.sh` | Development planning loop |
| `kickstart_ralph.sh` | Cron watchdog (restarts loop if dead) |
| `PROMPT.md` | Current task for Ralph loop |
| `IMPLEMENTATION_PLAN.md` | Master project plan |
| `personas.json` | Content persona definitions |
| `data/published.json` | Publishing state |
| `skills/sb60-blog/SKILL.md` | Clawdbot skill instructions |
| `agents/sb60-blog-agent/AGENT.md` | Ralph agent instructions |
| `.github/workflows/pages.yml` | Auto-deploy workflow |

---

## Launch Checklist

- [ ] GitHub repo created as `sb60-intel.github.io`
- [ ] GitHub Pages enabled in repo settings
- [ ] Local changes committed and pushed
- [ ] Cron job installed: `./skills/sb60-blog/scripts/setup_cron.sh`
- [ ] First post tested: `./skills/sb60-blog/scripts/run_now.sh`
- [ ] Site live at: https://sb60-intel.github.io

---

*Ralph is ready when you are.*
