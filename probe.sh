
set -u

HOST="192.168.122.82"
PORT="18081"
SOURCE_IP="192.168.122.194"

REQUESTS="${1:-1800}"
SLOW_MS="${2:-500}"
TIMEOUT_S=10
INTERVAL_S=1

URL="http://${HOST}:${PORT}/"
RUN_ID=$(date -u +%Y%m%dT%H%M%S)
CSV="probe-${RUN_ID}.csv"
ERROR_LOG="probe-errors-${RUN_ID}.log"

SUCCESS=0
SLOW=0
TIMEOUTS=0
ERRORS=0
HTTP_ERRORS=0

printf '%s\n' \
'timestamp_utc,request_id,exit_code,http_code,connect_ms,ttfb_ms,total_ms,local_ip,local_port,remote_ip,status' \
> "$CSV"

echo "================================================="
echo " ROOTLESSPORT HTTP LATENCY PROBE"
echo "================================================="
echo " Node B source : $SOURCE_IP"
echo " Node A target : $URL"
echo " Requests      : $REQUESTS"
echo " Slow threshold: ${SLOW_MS} ms"
echo " Curl timeout  : ${TIMEOUT_S} seconds"
echo " CSV output    : $CSV"
echo "================================================="
echo

printf '%-7s %-11s %-11s %-12s %-6s %s\n' \
  "Request" "TCP(ms)" "TTFB(ms)" "Total(ms)" "HTTP" "Status"

for ((i=1; i<=REQUESTS; i++)); do

    TS=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
    RID="probe-${RUN_ID}-${i}"

    RESULT=$(curl \
        --silent --show-error \
        --http1.1 \
        --noproxy '*' \
        --interface "$SOURCE_IP" \
        --connect-timeout 3 \
        --max-time "$TIMEOUT_S" \
        --output /dev/null \
        --header "X-Request-ID: $RID" \
        --header "Connection: close" \
        --write-out '%{http_code} %{time_connect} %{time_starttransfer} %{time_total} %{local_ip} %{local_port} %{remote_ip}' \
        "$URL" 2>>"$ERROR_LOG")

    RC=$?

    read -r CODE CONNECT TTFB TOTAL LOCAL_IP LOCAL_PORT REMOTE_IP \
        <<< "$RESULT"

    CODE="${CODE:-000}"
    CONNECT="${CONNECT:-0}"
    TTFB="${TTFB:-0}"
    TOTAL="${TOTAL:-0}"
    LOCAL_IP="${LOCAL_IP:-unknown}"
    LOCAL_PORT="${LOCAL_PORT:-0}"
    REMOTE_IP="${REMOTE_IP:-unknown}"

    CONNECT_MS=$(awk -v x="$CONNECT" 'BEGIN {printf "%.1f", x*1000}')
    TTFB_MS=$(awk -v x="$TTFB" 'BEGIN {printf "%.1f", x*1000}')
    TOTAL_MS=$(awk -v x="$TOTAL" 'BEGIN {printf "%.1f", x*1000}')

    IS_SLOW=$(awk -v x="$TOTAL_MS" -v limit="$SLOW_MS" \
        'BEGIN {print (x > limit) ? 1 : 0}')

    if (( RC == 28 )); then
        STATUS="TIMEOUT"
        TIMEOUTS=$((TIMEOUTS + 1))
    elif (( RC != 0 )); then
        STATUS="CURL_ERROR"
        ERRORS=$((ERRORS + 1))
    elif [[ "$CODE" != "200" ]]; then
        STATUS="HTTP_ERROR"
        HTTP_ERRORS=$((HTTP_ERRORS + 1))
    elif (( IS_SLOW == 1 )); then
        STATUS="SLOW"
        SLOW=$((SLOW + 1))
    else
        STATUS="OK"
        SUCCESS=$((SUCCESS + 1))
    fi

    printf '%-7d %-11s %-11s %-12s %-6s %s\n' \
        "$i" "$CONNECT_MS" "$TTFB_MS" \
        "$TOTAL_MS" "$CODE" "$STATUS"

    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$TS" "$RID" "$RC" "$CODE" \
        "$CONNECT_MS" "$TTFB_MS" "$TOTAL_MS" \
        "$LOCAL_IP" "$LOCAL_PORT" "$REMOTE_IP" "$STATUS" \
        >> "$CSV"

    sleep "$INTERVAL_S"
done

echo
echo "=============== SUMMARY ================="
echo "Total requests : $REQUESTS"
echo "Fast successes : $SUCCESS"
echo "Slow requests  : $SLOW"
echo "Timeouts       : $TIMEOUTS"
echo "Curl errors    : $ERRORS"
echo "HTTP errors    : $HTTP_ERRORS"
echo "CSV file       : $CSV"
echo "Error log      : $ERROR_LOG"
echo "========================================="

~                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
~                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
~                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
~                                                                      
