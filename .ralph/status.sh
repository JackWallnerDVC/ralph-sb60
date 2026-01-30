#!/usr/bin/env bash
# Ralph Status Report

cd /Users/jackwallner/clawd/ralph-sb60

echo "=== Ralph Status Report ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

echo "📊 Draft Queue:"
DRAFT_COUNT=$(ls -1 .ralph/drafts/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
echo "  Active drafts: $DRAFT_COUNT/5"
ls -la .ralph/drafts/draft-*.md 2>/dev/null || echo "  (none)"

echo ""
echo "📈 Published Posts:"
ls -1 _posts/*.md 2>/dev/null | wc -l | xargs echo "  Total:"
ls -1 _posts/*.md 2>/dev/null | tail -3 | sed 's/^/  - /'

echo ""
echo "⏱️ Rate Limit Gateway:"
.ralph/rate_limit_gateway.sh status 2>/dev/null || echo "  Gateway not initialized"

echo ""
echo "📋 Recent Activity:"
echo "  Research:  $(tail -1 .ralph/research.log 2>/dev/null | cut -d: -f1-3 || echo 'N/A')"
echo "  Draft:     $(tail -1 .ralph/draft_worker.log 2>/dev/null | cut -d: -f1-3 || echo 'N/A')"
echo "  Publish:   $(tail -1 .ralph/publish.log 2>/dev/null | cut -d: -f1-3 || echo 'N/A')"

echo ""
echo "🔄 Cron Jobs:"
crontab -l 2>/dev/null | grep -E "ralph" | grep -v "^#" | sed 's/^/  /' || echo "  None found"

echo ""
echo "✅ Status check complete"
