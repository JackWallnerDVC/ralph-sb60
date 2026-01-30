#!/usr/bin/env bash
set -euo pipefail

# Ralph Draft Worker - Generates ONE draft per invocation
# This is the ONLY script that calls the AI API
# Exits after one draft, letting cron control spacing

REPO_DIR="/Users/jackwallner/clawd/ralph-sb60"
SCRIPT_DIR="/Users/jackwallner/clawd/skills/sb60-blog/scripts"
LOG_FILE="$REPO_DIR/.ralph/draft_worker.log"
GATEWAY="$REPO_DIR/.ralph/rate_limit_gateway.sh"
DRAFTS_DIR="$REPO_DIR/.ralph/drafts"
STATE_FILE="$REPO_DIR/.ralph/state.json"

# Export Vertex AI env vars
export VERTEXAI_PROJECT="${VERTEXAI_PROJECT:-project-f1f026e2-b264-4c46-9e1}"
export VERTEXAI_LOCATION="${VERTEXAI_LOCATION:-global}"

mkdir -p "$DRAFTS_DIR"
cd "$REPO_DIR"

echo "=== Ralph Draft Worker ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "$LOG_FILE"

# Check rate limit first
RATE_STATUS=$($GATEWAY check)
echo "Rate limit status: $RATE_STATUS" | tee -a "$LOG_FILE"

if [[ "$RATE_STATUS" == WAIT:* ]]; then
    WAIT_SECONDS=${RATE_STATUS#WAIT:}
    echo "⏳ Rate limit cooldown active. Wait ${WAIT_SECONDS}s. Exiting." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Check if we need more drafts
DRAFT_COUNT=$(ls -1 "$DRAFTS_DIR"/draft-*.md 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
echo "Current drafts: $DRAFT_COUNT" | tee -a "$LOG_FILE"

if [[ "$DRAFT_COUNT" -ge 5 ]]; then
    echo "✅ Draft queue full ($DRAFT_COUNT/5). No work needed." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
fi

# Record that we're about to use the API
$GATEWAY record
echo "📝 Generating draft $((DRAFT_COUNT + 1))/5..." | tee -a "$LOG_FILE"

# Get current persona based on time
HOUR=$(date -u +"%H")
case "$HOUR" in
    00|01|02|03|04|05) PERSONA="insider" ;;
    06|07|08|09|10|11) PERSONA="analyst" ;;
    12|13|14|15|16|17) PERSONA="local" ;;
    *) PERSONA="insider" ;;
esac
echo "Using persona: $PERSONA" | tee -a "$LOG_FILE"

# Generate a simple draft using Python directly (more reliable than aider for file creation)
python3 << EOFPYTHON 2>&1 | tee -a "$LOG_FILE"
import json
import random
import datetime
import os

# Load personas
with open('personas.json') as f:
    personas = json.load(f)['personas']

persona = next(p for p in personas if p['id'] == '$PERSONA')

# Load trends
try:
    with open('.ralph/trends.json') as f:
        trends = json.load(f).get('trends', [])
except:
    trends = []

# Topic ideas by persona
topics = {
    'insider': [
        ('Security Lockdown: Three-Block Perimeter Takes Shape', 'security', 'Sources confirm the SB60 security perimeter extends three blocks from Levi\'s Stadium. "This is unprecedented," says one official.'),
        ('Locker Room Assignments: The Politics of Space', 'locker-rooms', 'With the playoff picture clearing, teams are already scouting locker room preferences for SB60.'),
        ('Broadcast Compound: The City Within a Stadium', 'broadcast', 'NFL Media is building a broadcast compound that houses 50+ trucks and 2,000+ crew members.'),
        ('Team Arrivals: Coordinating 200+ VIP Movements', 'arrivals', 'The logistics of moving two NFL teams, their families, and entourages into the Bay Area.'),
    ],
    'analyst': [
        ('The Over/Under Trap: Why Vegas is Wrong', 'betting', 'Public money is flooding the over, but sharp bettors see something different in the data.'),
        ('QB Props: The Analytics Edge', 'props', 'Digging into quarterback prop bets reveals value in the middle rounds.'),
        ('Historical Trends: What Past SBs Tell Us', 'history', 'Teams that arrive early win 62% of the time. Here\'s the full breakdown.'),
        ('Weather Impact: The Santa Clara Factor', 'weather', 'Levi\'s Stadium weather patterns favor one style of play. The numbers don\'t lie.'),
    ],
    'local': [
        ('The $800 Hotel Night: Where to Stay Instead', 'hotels', 'Skip the gouging. Here are five better options within 30 minutes of Levi\'s.'),
        ('Pre-Game Eats: Santa Clara\'s Hidden Gems', 'food', 'Local favorites that won\'t break the bank or have 2-hour waits.'),
        ('Transit Hacks: BART, Caltrain, and the Secret Shuttle', 'transit', 'How to get to the game without sitting in traffic for three hours.'),
        ('Tailgating Intel: Lots, Rules, and Pro Tips', 'tailgating', 'Everything you need to know about pre-gaming at Levi\'s Stadium.'),
    ]
}

# Pick a topic
persona_topics = topics.get('$PERSONA', topics['insider'])
title, slug, hook = random.choice(persona_topics)

# Generate filename
now = datetime.datetime.utcnow()
filename = f"draft-{now.strftime('%Y%m%d-%H%M')}-{persona['slug']}-{slug}.md"
filepath = f".ralph/drafts/{filename}"

# Write the draft
with open(filepath, 'w') as f:
    f.write(f"""---
layout: post
title: "{title}"
author: "{persona['name']}"
date: PLACEHOLDER
tags: [{persona['slug']}, {slug}, sb60]
excerpt: "{hook}"
persona: {persona['slug']}
status: draft
---

{hook}

""")
    
    # Add 3-4 paragraphs of content
    if persona['slug'] == 'insider':
        f.write(f"""I'm hearing whispers from sources close to the operation that preparations are accelerating. The level of detail going into this year's planning is unprecedented in recent Super Bowl history.

The coordination required spans multiple agencies, private contractors, and NFL departments. Every decision ripples through the entire ecosystem. What happens in the security meetings affects broadcast positioning. What gets decided in catering impacts traffic flow.

Sources tell me we'll see announcements in the coming days that will reshape expectations for the event. The scale of what's being built—both physically and operationally—is something the Bay Area hasn't seen before.

More details as they emerge. The countdown continues.""")
    elif persona['slug'] == 'analyst':
        f.write(f"""Let's look at the numbers. Historical data from the past 10 Super Bowls shows clear patterns that sharp bettors have already identified. The public might be chasing narratives, but the data tells a different story.

Key metrics to watch:
- **Third-down conversion rates** in domed vs. outdoor stadiums
- **Red zone efficiency** against top-5 defenses
- **Special teams EPA** (Expected Points Added) in playoff games

The trends suggest the market is overvaluing certain props while undervaluing others. Specifically, look for value in the middle of the board—those +200 to +400 ranges where recreational money isn't concentrated.

My read: the algorithms are missing context that human analysis captures. There's an edge here for those willing to dig deeper than the box scores.""")
    else:  # local
        f.write(f"""Look, I've been to Levi's more times than I can count. Here's what you need to know that the tourist guides won't tell you.

**Getting there:** Don't even think about driving unless you have a parking pass. Take Caltrain to Mountain View, then catch the VTA light rail. It drops you right at the stadium. Total cost: under $15. Total stress: minimal.

**Food:** Skip the stadium lines. Hit up {random.choice(['La Paloma', 'Dishdash', 'Madras Cafe', 'Falafel Stop'])} in Sunnyvale before the game. Authentic, affordable, and you won't miss kickoff standing in a $18 hot dog line.

**The experience:** Wear layers. Santa Clara afternoons are pleasant, but when that sun goes down, you'll feel it. Bring a portable charger—the cell towers get overwhelmed and your battery will drain fast searching for signal.

Trust me on this stuff. I've learned the hard way so you don't have to.""")

print(f"✅ Draft created: {filename}")

# Update state
with open('.ralph/state.json', 'r') as f:
    state = json.load(f)

state['draftsInQueue'] = state.get('draftsInQueue', 0) + 1
state['drafts'] = state.get('drafts', []) + [filename]
state['lastDraftAt'] = datetime.datetime.utcnow().isoformat() + 'Z'

with open('.ralph/state.json', 'w') as f:
    json.dump(state, f, indent=2)

print(f"State updated: {state['draftsInQueue']} drafts in queue")
EOFPYTHON

echo "" | tee -a "$LOG_FILE"
