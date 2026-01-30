#!/usr/bin/env bash
# Setup cron jobs for Ralph - FIXED SCHEDULE
# Research runs MORE often than drafts (feeds the pipeline)

echo "=== Setting up Ralph Job-Based Cron ==="

# Current crontab (preserve other entries)
CURRENT_CRON=$(crontab -l 2>/dev/null || echo "")

# Remove old Ralph entries
CLEANED_CRON=$(echo "$CURRENT_CRON" | grep -v -E "ralph|sb60-blog" || echo "")

# FIXED schedule: Research feeds drafts!
# Research: Every 5 min (keeps intel fresh)
# Draft: Every 15 min (uses fresh research, 3 AI calls spaced)
# Publish: Every 6 hours at :00
# Kickstart: Every 5 min (ensure workers healthy)

NEW_JOBS="# Ralph SB60 - FIXED Architecture (Research feeds Drafts)
# Research job - fetches AND analyzes trends (3-4 AI calls, spaced 10s)
*/5 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./ralph_research.sh >> .ralph/research.log 2>&1

# Draft worker - generates ONE draft (3 AI calls, spaced 10s)
*/15 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./ralph_draft_worker.sh >> .ralph/draft_worker.log 2>&1

# Publish job - every 6 hours (00:00, 06:00, 12:00, 18:00 UTC)
0 */6 * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./ralph_publish.sh >> .ralph/publish.log 2>&1

# Kickstart - ensures processes are healthy
*/5 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./kickstart_ralph.sh >> .ralph/kickstart.log 2>&1
"

# Combine and install
echo "${CLEANED_CRON}
${NEW_JOBS}" | crontab -

echo "✅ Cron jobs installed:"
crontab -l | grep -E "ralph|sb60" | grep -v "^#"
echo ""
echo "FIXED Schedule:"
echo "  Research:  Every 5 minutes (feeds fresh intel)"
echo "  Draft:     Every 15 minutes (uses research)"
echo "  Publish:   Every 6 hours"
echo "  Kickstart: Every 5 minutes"
