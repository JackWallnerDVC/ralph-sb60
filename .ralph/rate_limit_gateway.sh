#!/usr/bin/env bash
# Rate Limit Gateway - Prevents API choking
# Tracks last API call and enforces cooldown

GATEWAY_FILE="/Users/jackwallner/clawd/ralph-sb60/.ralph/api_gateway.json"
COOLDOWN_SECONDS=180  # 3 minutes between API calls

# Initialize gateway file if missing
init_gateway() {
    if [[ ! -f "$GATEWAY_FILE" ]]; then
        echo '{"lastCall": 0, "callsThisHour": 0, "hourStart": 0}' > "$GATEWAY_FILE"
    fi
}

# Check if API call is allowed
# Returns 0 if allowed, 1 if should wait
# Outputs: "WAIT:<seconds>" or "ALLOW"
check_rate_limit() {
    init_gateway
    
    local now=$(date +%s)
    local lastCall=$(jq -r '.lastCall' "$GATEWAY_FILE")
    local callsThisHour=$(jq -r '.callsThisHour' "$GATEWAY_FILE")
    local hourStart=$(jq -r '.hourStart' "$GATEWAY_FILE")
    
    # Reset hourly counter if hour has passed
    if (( now - hourStart >= 3600 )); then
        callsThisHour=0
        hourStart=$now
        jq ".hourStart = $hourStart | .callsThisHour = 0" "$GATEWAY_FILE" > "${GATEWAY_FILE}.tmp" && mv "${GATEWAY_FILE}.tmp" "$GATEWAY_FILE"
    fi
    
    # Check cooldown
    local elapsed=$(( now - lastCall ))
    if (( elapsed < COOLDOWN_SECONDS )); then
        local wait=$(( COOLDOWN_SECONDS - elapsed ))
        echo "WAIT:$wait"
        return 1
    fi
    
    echo "ALLOW"
    return 0
}

# Record an API call
record_call() {
    init_gateway
    local now=$(date +%s)
    local callsThisHour=$(jq -r '.callsThisHour' "$GATEWAY_FILE")
    callsThisHour=$(( callsThisHour + 1 ))
    
    jq ".lastCall = $now | .callsThisHour = $callsThisHour" "$GATEWAY_FILE" > "${GATEWAY_FILE}.tmp" && mv "${GATEWAY_FILE}.tmp" "$GATEWAY_FILE"
}

# Get status for logging
get_status() {
    init_gateway
    local lastCall=$(jq -r '.lastCall' "$GATEWAY_FILE")
    local callsThisHour=$(jq -r '.callsThisHour' "$GATEWAY_FILE")
    local now=$(date +%s)
    local elapsed=$(( now - lastCall ))
    local remaining=$(( COOLDOWN_SECONDS - elapsed ))
    
    if (( remaining > 0 )); then
        echo "COOLDOWN:${remaining}s|HOUR:${callsThisHour}"
    else
        echo "READY|HOUR:${callsThisHour}"
    fi
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
