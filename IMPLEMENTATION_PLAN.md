# SB60 Blog Implementation Plan

## Status: READY FOR LAUNCH

## Completed

### Infrastructure
- [x] Jekyll site structure with custom layouts
- [x] GitHub Pages workflow configured (`.github/workflows/pages.yml`)
- [x] 3 reporter personas defined in `personas.json`
- [x] Custom theme with SB60 branding
- [x] Author pages for each persona
- [x] Welcome post created

### Clawdbot Integration
- [x] Dedicated agent: `agents/sb60-blog-agent/`
- [x] Native skill: `skills/sb60-blog/`
- [x] Cron setup script for 4x daily publishing
- [x] Content generation helpers
- [x] Publishing automation scripts

### Content Pipeline
- [x] Persona rotation schedule (Insider → Analyst → Local → Rotating)
- [x] Post templates with YAML front-matter
- [x] State tracking in `data/published.json`
- [x] Git commit/push automation

## Remaining Tasks

### Pre-Launch (Manual)
1. [ ] Enable GitHub Pages in repo settings
2. [ ] Commit all files to main branch
3. [ ] Install cron job: `./skills/sb60-blog/scripts/setup_cron.sh`
4. [ ] Test first post: `./skills/sb60-blog/scripts/run_now.sh`

### Post-Launch (Auto)
- [ ] First automated post at next 6-hour interval
- [ ] Verify site updates correctly
- [ ] Monitor for 24 hours

## Launch Commands

```bash
# 1. Enable Pages (manual in GitHub UI)
# 2. Commit everything
cd /Users/jackwallner/clawd/ralph-sb60
git add .
git commit -m "SB60 Intel v1.0 launch"
git push origin main

# 3. Install cron
cd /Users/jackwallner/clawd/skills/sb60-blog
./scripts/setup_cron.sh

# 4. Test
cd /Users/jackwallner/clawd/skills/sb60-blog
./scripts/run_now.sh
```

## Architecture

```
ralph-sb60/
├── _config.yml           # Jekyll config
├── _posts/               # Blog posts (markdown)
├── _layouts/             # HTML templates
├── _data/personas.json   # Persona definitions
├── data/published.json   # Publishing state
├── .github/workflows/    # Auto-deploy to Pages
└── LAUNCH.md            # Launch instructions

skills/sb60-blog/
├── SKILL.md             # Clawdbot instructions
├── scripts/
│   ├── publish.sh       # Git operations
│   ├── generate_post.py # Metadata helper
│   ├── setup_cron.sh    # Install schedule
│   └── run_now.sh       # Manual trigger

agents/sb60-blog-agent/
├── AGENT.md             # Agent instructions
├── SOUL.md              # Personality
└── IDENTITY.md          # Metadata
```

## Schedule

| UTC | Persona | Status |
|-----|---------|--------|
| 00:00 | Insider | Cron scheduled |
| 06:00 | Analyst | Cron scheduled |
| 12:00 | Local | Cron scheduled |
| 18:00 | Rotating | Cron scheduled |

---

STATUS: COMPLETE (Ready for Launch)
