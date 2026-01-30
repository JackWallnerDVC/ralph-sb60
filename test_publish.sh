#!/usr/bin/env bash
# Quick publish test - simple direct approach

set -e

cd /Users/jackwallner/clawd/ralph-sb60

echo "=== Publish Test ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Check for drafts
DRAFT_COUNT=$(ls -1 .ralph/drafts/draft-*.md 2>/dev/null | wc -l)
if [ "$DRAFT_COUNT" -eq 0 ]; then
    echo "❌ No drafts found"
    exit 1
fi

echo "Found $DRAFT_COUNT draft(s):"
ls -la .ralph/drafts/draft-*.md

# Get first draft
DRAFT=$(ls -1 .ralph/drafts/draft-*.md | head -1)
echo ""
echo "Publishing: $(basename $DRAFT)"

# Create post filename
NOW_DATE=$(date -u +%Y-%m-%d)
NOW_TIME=$(date -u +%H-%M)
SLUG=$(basename "$DRAFT" .md | sed 's/draft-[0-9]*-[0-9]*-[0-9]*-//' | sed 's/insider-//;s/analyst-//;s/local-//')
POST_FILE="_posts/${NOW_DATE}-${NOW_TIME}-${SLUG}.md"

# Copy with date update
sed "s/date: PLACEHOLDER/date: $(date -u +"%Y-%m-%d %H:%M:%S") +0000/; s/status: draft/status: published/" "$DRAFT" > "$POST_FILE"

# Archive draft
mv "$DRAFT" .ralph/drafts/archive/

echo "Created: $POST_FILE"
cat "$POST_FILE" | head -15
echo ""

# Build
echo "Building Jekyll..."
if bundle exec jekyll build 2>&1 | tail -20; then
    echo "✅ Build successful"
    
    # Git operations
    git add _posts/ .ralph/drafts/
    git commit -m "test publish: $(date -u +%H:%M) UTC" || echo "Commit may be empty"
    git push origin main
    echo "✅ Pushed to GitHub"
    echo ""
    echo "Site will update at: https://jackwallnerdvc.github.io/ralph-sb60/"
else
    echo "❌ Build failed"
    exit 1
fi
