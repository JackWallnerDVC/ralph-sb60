#!/usr/bin/env bash
# Rate Limit Gateway - Prevents API choking
# Tracks last API call and enforces cooldown

GATEWAY_FILE="/Users/jackwallner/clawd/ralph-sb60/.ralph/api_gateway.json"
COOLDOWN_SECONDS=180  # 3 minutes between API calls

# Initialize gateway file if missing
init_gateway() {
    if [[ ! -f "$GATEWAY_FILE" ]]; then
        python3 -c "import json; json.dump({'lastCall': 0, 'callsThisHour': 0, 'hourStart': 0}, open('$GATEWAY_FILE', 'w'))"
    fi
}

# Check if API call is allowed
# Returns 0 if allowed, 1 if should wait
# Outputs: "WAIT:<seconds>" or "ALLOW"
check_rate_limit() {
    init_gateway
    
    python3 << EOF
import json
import time

try:
    with open('$GATEWAY_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'lastCall': 0, 'callsThisHour': 0, 'hourStart': 0}

now = int(time.time())
lastCall = data.get('lastCall', 0)
hourStart = data.get('hourStart', 0)

# Reset hourly counter if hour has passed
if now - hourStart >= 3600:
    data['hourStart'] = now
    data['callsThisHour'] = 0
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
    data = {'lastCall': 0, 'callsThisHour': 0, 'hourStart': 0}

now = int(time.time())
data['lastCall'] = now
data['callsThisHour'] = data.get('callsThisHour', 0) + 1

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
    data = {'lastCall': 0, 'callsThisHour': 0, 'hourStart': 0}

now = int(time.time())
lastCall = data.get('lastCall', 0)
callsThisHour = data.get('callsThisHour', 0)
elapsed = now - lastCall
remaining = $COOLDOWN_SECONDS - elapsed

if remaining > 0:
    print(f'COOLDOWN:{remaining}s|HOUR:{callsThisHour}')
else:
    print(f'READY|HOUR:{callsThisHour}')
EOF
}

# Main entry point
case "${1:-}" in
    check)
        check_rate_limit
        ;;
    record)
        record_call
        ;;
    status)
        get_status
        ;;
    *)
        echo "Usage: $0 {check|record|status}"
        exit 1
        ;;
esac
