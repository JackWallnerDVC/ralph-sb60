#!/usr/bin/env bash
# Rate Limit Gateway - Spaces API calls for ~7 calls/minute budget
# Minimum 10 seconds between calls (6 calls/min sustainable)

GATEWAY_FILE="/Users/jackwallner/clawd/ralph-sb60/.ralph/api_gateway.json"
COOLDOWN_SECONDS=10  # 10 seconds between API calls = 6/min, well under 7/min budget

# Initialize gateway file if missing
init_gateway() {
    if [[ ! -f "$GATEWAY_FILE" ]]; then
        python3 -c "import json; json.dump({'lastCall': 0, 'callsThisMinute': 0, 'minuteStart': 0}, open('$GATEWAY_FILE', 'w'))"
    fi
}

# Check if API call is allowed
check_rate_limit() {
    init_gateway
    
    python3 << EOF
import json
import time

try:
    with open('$GATEWAY_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'lastCall': 0, 'callsThisMinute': 0, 'minuteStart': 0}

now = int(time.time())
lastCall = data.get('lastCall', 0)
minuteStart = data.get('minuteStart', 0)

# Reset minute counter
if now - minuteStart >= 60:
    data['minuteStart'] = now
    data['callsThisMinute'] = 0
    with open('$GATEWAY_FILE', 'w') as f:
        json.dump(data, f)

# Check cooldown
elapsed = now - lastCall
if elapsed < $COOLDOWN_SECONDS:
    wait = $COOLDOWN_SECONDS - elapsed
    print(f'WAIT:{wait}')
else:
    print('ALLOW')
EOF
}

# Wait for rate limit to clear, then proceed
wait_for_clear() {
    while true; do
        STATUS=$(check_rate_limit)
        if [[ "$STATUS" == "ALLOW" ]]; then
            return 0
        fi
        WAIT=${STATUS#WAIT:}
        echo "  ⏱️  Waiting ${WAIT}s for rate limit..." >&2
        sleep "$WAIT"
    done
}

# Record an API call
record_call() {
    init_gateway
    
    python3 << EOF
import json
import time

try:
    with open('$GATEWAY_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'lastCall': 0, 'callsThisMinute': 0, 'minuteStart': 0}

now = int(time.time())
data['lastCall'] = now
data['callsThisMinute'] = data.get('callsThisMinute', 0) + 1

with open('$GATEWAY_FILE', 'w') as f:
    json.dump(data, f)
EOF
}

# Get status for logging
get_status() {
    init_gateway
    
    python3 << EOF
import json
import time

try:
    with open('$GATEWAY_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'lastCall': 0, 'callsThisMinute': 0, 'minuteStart': 0}

now = int(time.time())
lastCall = data.get('lastCall', 0)
callsThisMinute = data.get('callsThisMinute', 0)
elapsed = now - lastCall
remaining = $COOLDOWN_SECONDS - elapsed

if remaining > 0:
    print(f'COOLDOWN:{remaining}s|MIN:{callsThisMinute}')
else:
    print(f'READY|MIN:{callsThisMinute}')
EOF
}

# Main entry point
case "${1:-}" in
    check)
        check_rate_limit
        ;;
    wait)
        wait_for_clear
        ;;
    record)
        record_call
        ;;
    status)
        get_status
        ;;
    *)
        echo "Usage: $0 {check|wait|record|status}"
        exit 1
        ;;
esac
