#!/bin/bash

source /etc/fail2ban/abuseipdb.env

IP="$1"
JAIL="$2"

log() {
  echo "[$(date '+%F %T')] $*" >> "/var/log/fail2ban/abuseipdb.log"
}

log "Consultando AbuseIPDB para $IP"

RESPONSE=$(curl -s --max-time 10 -X POST "https://api.abuseipdb.com/api/v2/report" \
    -H "Key: $ABUSEIPDB_API_KEY" \
    -H "Accept: application/json" \
    -d "ip=$IP" \
    -d "categories=22" \
    -d "comment=Fail2Ban report from jail:  $JAIL" 2>/dev/null)

if !  echo "$RESPONSE" | grep -q '"abuseConfidenceScore"'; then
    log "ERROR al reportar a AbuseIPDB"
    log "Respuesta: $REPORT_RESPONSE"
    exit 1
fi

SCORE=$(echo "$RESPONSE" | grep -o '"abuseConfidenceScore":[0-9]*' | cut -d: -f2)

if [[ -z "$SCORE" ]]; then
  log "ERROR obteniendo score para $IP"
  exit 0
fi

log "Score AbuseIPDB: $SCORE%"

if (( SCORE > 80 )); then
  log "IP $IP es HIGH RISK → baneando 30 días"
  fail2ban-client set "highrisk" banip "$IP"
else
  log "IP $IP riesgo normal"
fi