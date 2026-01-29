#!/usr/bin/env bash
# Ralph Kickstart Cron Script
# Checks if the SB60 blog Ralph loop is running and starts it if not.

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
LOG_FILE="$REPO_DIR/.ralph/kickstart.log"
mkdir -p "$REPO_DIR/.ralph"

if pgrep -f "ralph_loop.sh" > /dev/null; then
    echo "$(date): Ralph loop is already running." >> "$LOG_FILE"
else
    echo "$(date): Ralph loop not found. Kickstarting..." >> "$LOG_FILE"
    cd "$REPO_DIR"
    nohup ./ralph_loop.sh > /dev/null 2>&1 &
fi
