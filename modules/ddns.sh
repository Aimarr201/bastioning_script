#!/bin/bash

log "Configurando DDNS con Cloudflare..."

# Validaciones
[[ -z "$DDNS_APIKEY" ]]    && error_exit "DDNS_APIKEY no está definido en config.conf"
[[ -z "$DDNS_ZONE_ID" ]]   && error_exit "DDNS_ZONE_ID no está definido en config.conf"
[[ -z "$DDNS_DOMAIN" ]]    && error_exit "DDNS_DOMAIN no está definido en config.conf"

install_package curl
install_package jq

# Crear directorio
mkdir -p /opt/cloudflare-ddns

SCRIPT_FILE="/opt/cloudflare-ddns/update.sh"

# Crear script de actualización
cat > "$SCRIPT_FILE" <<EOF
#!/bin/bash

API_TOKEN="$DDNS_APIKEY"
ZONE_ID="$DDNS_ZONE_ID"
DOMAIN="$DDNS_DOMAIN"

IP_ACTUAL=\$(curl -s https://ifconfig.me)

RECORD_ID=\$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records?type=A&name=\$DOMAIN" \
  -H "Authorization: Bearer \$API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "\$RECORD_ID" ] || [ "\$RECORD_ID" == "null" ]; then
  echo "No se encontró el registro A para \$DOMAIN"
  exit 1
fi

IP_DNS=\$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records/\$RECORD_ID" \
  -H "Authorization: Bearer \$API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result.content')

if [ "\$IP_ACTUAL" != "\$IP_DNS" ]; then
  
  curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records/\$RECORD_ID" \
    -H "Authorization: Bearer \$API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"\$DOMAIN\",\"content\":\"\$IP_ACTUAL\",\"ttl\":120,\"proxied\":false}" > /dev/null

  echo "IP actualizada: \$IP_DNS → \$IP_ACTUAL"
else
  echo "Sin cambios. IP actual: \$IP_ACTUAL"
fi
EOF

chmod +x "$SCRIPT_FILE"

# Añadir al cron (sin duplicar)
add_cronjob "$DDNS_CRON /bin/bash $SCRIPT_FILE"

log "DDNS con Cloudflare configurado correctamente."