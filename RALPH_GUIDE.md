# Ralph Guide - SB60 Blog Automation

## Overview

**Ralph** is the autonomous content engine for the SB60 Blog. It now runs in **Continuous Mode** - always researching and drafting in the background - with scheduled publishes every 6 hours.

**Live Site:** https://jackwallnerdvc.github.io/ralph-sb60/

---

## New Architecture (Continuous Mode)

```
┌─────────────────────────────────────────────────────────────────┐
│                    RALPH CONTINUOUS MODE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────┐      ┌─────────────────────┐         │
│   │  Ralph Continuous   │      │  Scheduled Publish  │         │
│   │  (Always Running)   │─────▶│  (Every 6 Hours)    │         │
│   │                     │      │                     │         │
│   │ • Researches SB60   │      │ • Selects best draft│         │
│   │ • Drafts posts      │      │ • Polishes & moves  │         │
│   │ • Maintains queue   │      │ • Commits & pushes  │         │
│   │   (3-5 ready)       │      │ • Triggers deploy   │         │
│   └─────────────────────┘      └─────────────────────┘         │
│            │                              │                     │
│            ▼                              ▼                     │
│   ┌─────────────────────┐      ┌─────────────────────┐         │
│   │  .ralph/drafts/     │      │   _posts/*.md       │         │
│   │  (draft queue)      │      │   (published)       │         │
│   └─────────────────────┘      └─────────────────────┘         │
│                                                                  │
│   Kickstart: Every 5 min via cron (ensures Ralph stays running) │
│   Publish:   Every 6 hours via cron (00:00, 06:00, 12:00, 18:00)│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why Continuous Mode?

Instead of generating content at publish time (rushed, lower quality), Ralph now:
1. **Continuously researches** SB60 news and developments
2. **Drafts posts** throughout the day when inspiration strikes
3. **Maintains a queue** of 3-5 publication-ready drafts
4. **Publishes the best draft** at scheduled times

Result: Higher quality, more thoughtful content that feels timely and well-researched.

---

## Quick Start

### 1. Ensure GitHub Access is Configured

The push is failing due to auth. You need to set up GitHub credentials:

**Option A: SSH Key (Recommended)**
```bash
# Check if you have an SSH key
ls ~/.ssh/id_rsa.pub ~/.ssh/id_ed25519.pub 2>/dev/null

# If not, generate one
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
# Copy the output and add to GitHub → Settings → SSH Keys

# Update remote to use SSH
cd /Users/jackwallner/clawd/ralph-sb60
git remote set-url origin git@github.com:JackWallnerDVC/ralph-sb60.git
```

**Option B: GitHub CLI**
```bash
# Install gh if not already
brew install gh

# Authenticate
gh auth login

# Then push will work
cd /Users/jackwallner/clawd/ralph-sb60
git push origin main
```

**Option C: HTTPS with Token**
```bash
# Create token at https://github.com/settings/tokens
# Use token as password when prompted
git push origin main
# Username: JackWallnerDVC
# Password: ghp_xxxxxxxxxxxx (your token)
```

### 2. Install Cron Jobs

```bash
cd /Users/jackwallner/clawd/skills/sb60-blog/scripts
./setup_cron.sh
```

This installs:
- **Every 5 minutes**: Checks if Ralph continuous is running, restarts if needed
- **Every 6 hours**: Publishes the best draft from queue

### 3. Start Ralph Continuous (First Time)

```bash
cd /Users/jackwallner/clawd/ralph-sb60
./ralph_continuous.sh &
```

Or let the kickstart cron handle it (runs every 5 min).

### 4. Verify Everything Works

```bash
# Check Ralph is running
pgrep -f "ralph_continuous" && echo "✅ Running" || echo "❌ Down"

# Check cron jobs
crontab -l | grep -E "ralph|sb60"

# Check draft queue
ls -la /Users/jackwallner/clawd/ralph-sb60/.ralph/drafts/

# Check Ralph's state
cat /Users/jackwallner/clawd/ralph-sb60/.ralph/state.json
```

---

## How It Works

### Ralph Continuous (`ralph_continuous.sh`)

Runs indefinitely (restarted every 5 min by cron if it crashes):

**Loop:**
1. Checks draft queue count
2. If < 3 drafts, generates a new one:
   - Reads current state and personas
   - Reviews existing posts to avoid duplicates
   - Creates draft in `.ralph/drafts/`
   - Updates state.json
3. Sleeps 15 minutes
4. Repeats

**Draft Filename Format:**
```
draft-YYYYMMDD-HHMM-{persona}-{slug}.md
```

**Draft Contents:**
```yaml
---
layout: post
title: "Post Title"
author: "Persona Name"
date: PLACEHOLDER
tags: [tag1, tag2]
excerpt: "Brief excerpt..."
---

Full content here (300-500 words)...
```

### Scheduled Publisher (`publish_scheduled.sh`)

Triggered every 6 hours by cron:

**Process:**
1. Pulls latest from git
2. Determines current persona from UTC hour
3. Selects best matching draft from queue
4. Updates date to current timestamp
5. Moves to `_posts/YYYY-MM-DD-HH-MM-{slug}.md`
6. Builds Jekyll locally to verify
7. Commits and pushes
8. Updates `data/published.json`

**Persona Schedule:**
| UTC | Persona | Content Style |
|-----|---------|---------------|
| 00:00 | **Insider** | "Sources say..." behind-the-scenes |
| 06:00 | **Analyst** | Stats, odds, predictions |
| 12:00 | **Local** | "You gotta check out..." SF tips |
| 18:00 | **Rotating** | Cycles through all three |

### Kickstart (`kickstart_ralph.sh`)

Run every 5 minutes via cron:
- Checks if `ralph_continuous.sh` is running
- If not, starts it in background
- Logs activity to `.ralph/kickstart.log`

---

## File Structure

```
ralph-sb60/
├── ralph_continuous.sh       # Main always-on engine
├── kickstart_ralph.sh        # Cron watchdog (every 5 min)
├── ralph_loop.sh            # Old planning loop (deprecated)
├── .ralph/
│   ├── drafts/              # Draft queue (3-5 posts)
│   │   ├── draft-20260129-1100-insider-stadium-prep.md
│   │   └── ...
│   ├── state.json           # Ralph's current status
│   ├── continuous.log       # Ralph continuous output
│   ├── publish.log          # Scheduled publish output
│   └── kickstart.log        # Kickstart cron log
├── _posts/                  # Published posts
├── data/
│   └── published.json       # Published history
└── .github/workflows/
    └── pages.yml            # Auto-deploy to Pages
```

---

## Adjusting Ralph

### Change Publishing Frequency

Edit `skills/sb60-blog/scripts/setup_cron.sh`:

```bash
# Current: Every 6 hours
PUBLISH_LINE="0 */6 * * * $PUBLISH_CMD"

# Change to: Every 12 hours
PUBLISH_LINE="0 */12 * * * $PUBLISH_CMD"

# Change to: Daily at 9am UTC
PUBLISH_LINE="0 9 * * * $PUBLISH_CMD"
```

Then reinstall:
```bash
./setup_cron.sh
```

### Change Draft Generation Frequency

Edit `ralph_continuous.sh`:

```bash
# Current: Every 15 minutes
sleep 900

# Change to: Every 30 minutes
sleep 1800

# Change to: Every hour
sleep 3600
```

### Change Kickstart Check Frequency

Edit crontab directly:

```bash
crontab -e

# Current: Every 5 minutes
*/5 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./kickstart_ralph.sh

# Change to: Every 10 minutes
*/10 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./kickstart_ralph.sh
```

### Add/Change Personas

1. Edit `ralph-sb60/personas.json`
2. Update rotation in `data/published.json`
3. Update `agents/sb60-blog-agent/AGENT.md`
4. Restart Ralph continuous:
   ```bash
   pkill -f ralph_continuous
   ./ralph_continuous.sh &
   ```

### Change Draft Queue Size

Edit `ralph_continuous.sh`:

```bash
# Current: Maintain 3-5 drafts
if [ "$drafts_count" -lt 3 ]; then

# Change to: Maintain 5-8 drafts
if [ "$drafts_count" -lt 5 ]; then
```

### Emergency Manual Publish

If Ralph is down and you need a post NOW:

```bash
cd /Users/jackwallner/clawd/ralph-sb60

# Option 1: Run scheduled publisher manually
../skills/sb60-blog/scripts/publish_scheduled.sh

# Option 2: Generate emergency post
cd ../skills/sb60-blog/scripts
python3 generate_post.py analyst  # or insider, local

# Then commit manually
cd ../../ralph-sb60
git add _posts/
git commit -m "[Emergency] Title - $(date -u +%H:%M)"
git push origin main
```

---

## Troubleshooting

### Ralph Not Running

```bash
# Check if running
pgrep -f "ralph_continuous" || echo "Not running"

# Start manually
cd /Users/jackwallner/clawd/ralph-sb60
./ralph_continuous.sh &

# Or wait for kickstart cron (runs every 5 min)
```

### No Drafts in Queue

```bash
# Check Ralph's status
cat /Users/jackwallner/clawd/ralph-sb60/.ralph/state.json

# Check continuous log for errors
tail -f /Users/jackwallner/clawd/ralph-sb60/.ralph/continuous.log

# Check if Vertex AI is working
echo $VERTEXAI_PROJECT
echo $VERTEXAI_LOCATION
```

### Git Push Failing

```bash
# Check remote
cd /Users/jackwallner/clawd/ralph-sb60
git remote -v

# Test auth
git push origin main

# If fails, see "Quick Start → GitHub Access" section above
```

### Jekyll Build Failing

```bash
cd /Users/jackwallner/clawd/ralph-sb60

# Check for syntax errors
bundle exec jekyll build 2>&1 | head -50

# Check draft that failed
cat .ralph/drafts/draft-*.md | head -20
```

### Cron Jobs Not Running

```bash
# Check crontab
crontab -l | grep -E "ralph|sb60"

# Check cron service
sudo launchctl list | grep cron

# Check logs
 tail -f /Users/jackwallner/clawd/skills/sb60-blog/cron.log
```

---

## Useful Commands

```bash
# Quick status check
echo "=== Ralph Status ===" && pgrep -f "ralph_continuous" > /dev/null && echo "✅ Running" || echo "❌ Down"
echo "=== Draft Queue ===" && ls -1 /Users/jackwallner/clawd/ralph-sb60/.ralph/drafts/*.md 2>/dev/null | wc -l | xargs echo "Drafts:"
echo "=== Last Publish ===" && cat /Users/jackwallner/clawd/ralph-sb60/data/published.json | grep -A2 "lastPublish"
echo "=== Next Publish ===" && cat /Users/jackwallner/clawd/ralph-sb60/.ralph/state.json | grep "nextPublish"

# View logs
tail -f /Users/jackwallner/clawd/ralph-sb60/.ralph/continuous.log
tail -f /Users/jackwallner/clawd/ralph-sb60/.ralph/publish.log
tail -f /Users/jackwallner/clawd/ralph-sb60/.ralph/kickstart.log

# Stop Ralph
pkill -f "ralph_continuous"

# Start Ralph
cd /Users/jackwallner/clawd/ralph-sb60 && ./ralph_continuous.sh &

# Force publish now
/Users/jackwallner/clawd/skills/sb60-blog/scripts/publish_scheduled.sh
```

---

## Launch Checklist

- [ ] GitHub repo created as `ralph-sb60` under `JackWallnerDVC`
- [ ] GitHub Pages enabled in repo settings
- [ ] Local commits pushed to GitHub (fix auth first)
- [ ] Cron jobs installed: `./skills/sb60-blog/scripts/setup_cron.sh`
- [ ] Ralph continuous started (or wait for kickstart)
- [ ] First draft generated in `.ralph/drafts/`
- [ ] Test publish: `./skills/sb60-blog/scripts/publish_scheduled.sh`
- [ ] Site live at: https://jackwallnerdvc.github.io/ralph-sb60/
- [ ] Monitor for 24 hours

---

*Ralph is always working so your content is always ready.*
