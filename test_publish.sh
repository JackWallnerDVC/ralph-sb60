#!/usr/bin/env bash
# Quick publish test - simple direct approach

set -e

cd /Users/jackwallner/clawd/ralph-sb60

echo "=== Publish Test ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Check drafts
DRAFTS=(.ralph/drafts/draft-*.md)
if [ ! -f "${DRAFTS[0]}" ]; then
    echo "❌ No drafts found"
    exit 1
fi

echo "Found ${#DRAFTS[@]} draft(s):"
ls -la .ralph/drafts/draft-*.md

# Pick the first draft
DRAFT="${DRAFTS[0]}"
echo ""
echo "Publishing: $(basename $DRAFT)"

# Read and update
NOW=$(date -u +"%Y-%m-%d %H:%M:%S")
SLUG=$(basename "$DRAFT" .md | sed 's/draft-[0-9]*-[0-9]*-//')
POST_FILE="_posts/$(date -u +%Y-%m-%d)-$(date -u +%H-%M)-${SLUG}.md"

# Copy with date update
sed "s/date: PLACEHOLDER/date: $NOW +0000/; s/status: draft/status: published/" "$DRAFT" > "$POST_FILE"

# Archive draft
mv "$DRAFT" .ralph/drafts/archive/

echo "Created: $POST_FILE"
echo ""

# Build
echo "Building Jekyll..."
if bundle exec jekyll build; then
    echo "✅ Build successful"
    
    # Git operations
    git add _posts/ .ralph/drafts/
    git commit -m "test publish: $(date -u +%H:%M) UTC" || true
    git push origin main
    echo "✅ Pushed to GitHub"
    echo ""
    echo "Site will update at: https://jackwallnerdvc.github.io/ralph-sb60/"
else
    echo "❌ Build failed"
    exit 1
fi
