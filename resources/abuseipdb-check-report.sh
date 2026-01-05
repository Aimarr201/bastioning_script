#!/bin/bash

API_KEY
IP="${1}"
JAIL="${2}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "/var/log/fail2ban/abuseipdb.log"
}


log "Procesando IP: $IP (Jail: $JAIL)"

# REPORTAR A ABUSEIPDB Y OBTENER SCORE
log "Reportando a AbuseIPDB..."

REPORT_RESPONSE=$(curl -s --max-time 10 -X POST "https://api.abuseipdb.com/api/v2/report" \
    -H "Key: $API_KEY" \
    -H "Accept: application/json" \
    -d "ip=$IP" \
    -d "categories=22" \
    -d "comment=Fail2Ban report from jail:  $JAIL" 2>/dev/null)

# Validar respuesta
if !  echo "$REPORT_RESPONSE" | grep -q '"abuseConfidenceScore"'; then
    log "ERROR al reportar a AbuseIPDB"
    log "Respuesta: $REPORT_RESPONSE"
    exit 1
fi

# Extraer el score del reporte
ABUSE_SCORE=$(echo "$REPORT_RESPONSE" | grep -o '"abuseConfidenceScore":[0-9]*' | cut -d':' -f2)

if [[ -z "$ABUSE_SCORE" ]]; then
    log "ERROR: No se pudo extraer el score de abuso"
    exit 1
fi

log "Reporte enviado a AbuseIPDB | Score: $ABUSE_SCORE%"

# DECIDIR SI BANEAR POR 30 DÍAS
if awk "BEGIN {exit ! ($ABUSE_SCORE > 80)}"; then
    log "Score > 80%:  BANEANDO POR 30 DÍAS"

    # Actualizar bantime a 30 días (2592000 segundos)
    fail2ban-client set "$JAIL" bantime 2592000 && log "Bloqueo de 30 dias por actividad sospechosa"

    exit 0
else
    log "Score ≤ 80%: Bantime normal aplicado"
    exit 0
fi