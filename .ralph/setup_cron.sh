#!/usr/bin/env bash
# Setup cron jobs for Ralph - Job-based architecture
# Spreads API calls to avoid rate limits

echo "=== Setting up Ralph Job-Based Cron ==="

# Current crontab (preserve other entries)
CURRENT_CRON=$(crontab -l 2>/dev/null || echo "")

# Remove old Ralph entries
CLEANED_CRON=$(echo "$CURRENT_CRON" | grep -v -E "ralph|sb60-blog" || echo "")

# New job-based schedule
# Research: Every 15 min (no API calls, just scraping)
# Draft: Every 10 min (API calls, but spaced)
# Publish: Every 6 hours at :00
# Kickstart: Every 5 min (ensure workers are running)

NEW_JOBS="# Ralph SB60 - Job-Based Architecture (API-friendly)
# Research job - fetches trends/intel (no API calls)
*/15 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./ralph_research.sh >> .ralph/research.log 2>&1

# Draft worker - generates ONE draft per run (API call, spaced 10 min)
*/10 * * * * cd /Users/jackwallner/clawd/ralph-sb60 && ./ralph_draft_worker.sh >> .ralph/draft_worker.log 2>&1

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
echo "Schedule:"
echo "  Research:  Every 15 minutes (no API)"
echo "  Draft:     Every 10 minutes (spaced API calls)"
echo "  Publish:   Every 6 hours"
echo "  Kickstart: Every 5 minutes"
