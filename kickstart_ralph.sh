#!/usr/bin/env bash
# Ralph Kickstart - Continuous Mode
# Ensures Ralph is always running in the background
# Run this via cron every 5 minutes

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
LOG_FILE="$REPO_DIR/.ralph/kickstart.log"
mkdir -p "$REPO_DIR/.ralph"

# Check if Ralph continuous is running
if pgrep -f "ralph_continuous.sh" > /dev/null; then
    echo "$(date): Ralph continuous is running." >> "$LOG_FILE"
else
    echo "$(date): Ralph continuous not found. Kickstarting..." >> "$LOG_FILE"
    cd "$REPO_DIR"
    nohup ./ralph_continuous.sh > "$REPO_DIR/.ralph/continuous.log" 2>&1 &
    echo "$(date): Ralph continuous started (PID: $!)" >> "$LOG_FILE"
fi

# Also ensure no zombie processes
ZOMBIES=$(pgrep -f "ralph_loop.sh" || true)
if [ -n "$ZOMBIES" ]; then
    echo "$(date): Cleaning up old ralph_loop processes" >> "$LOG_FILE"
    kill $ZOMBIES 2>/dev/null || true
fi
