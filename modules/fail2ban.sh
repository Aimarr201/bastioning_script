#!/bin/bash

#################################################
#      Script de configuracion de fail2ban      #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################

# instalar paquetes
install_package fail2ban

# iniciar y habilitar servicio
service_start fail2ban
service_enable fail2ban

# crear el archivo de configuracion local
touch /etc/fail2ban/jail.local

# funciones para la configuracion de jail.local
fail_defaults() {
    cat >> /etc/fail2ban/jail.local <<EOF
[DEFAULT]

bantime  = $F2B_DEFBANTIME
findtime = $F2B_DEFFINDTIME
maxretry = $F2B_DEFMAXRETRY

EOF
    log "configuraciones para jaulas default añadida"
}

fail_whitelist() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "[DEFAULT]" ] && echo -e "[DEFAULT]\n" > "/etc/fail2ban/jail.local"

    echo -e "ignoreip = $F2B_WHITELIST\n" >> "/etc/fail2ban/jail.local"
    log "direcciones ip permitidas añadidas a la lista blanca"
}

fail_increment() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "[DEFAULT]" ] && echo -e "[DEFAULT]\n" > "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF
bantime.increment    = $F2B_BANTIMEINCREMENT
bantime.rndtime      = $F2B_RNDTIME
bantime.maxtime      = $F2B_MAXTIME
bantime.factor       = $F2B_FACTOR
bantime.overalljails = $F2B_OVERALL

EOF
    log "incremento de tiempo de bloqueo añadido"
}

fail_ipdb() {
    if [ "$F2B_SENDREPORTS" == "true" ]; then 
        install_package curl
        replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "abuseipdb_apikey" "$F2B_APIKEY"

        [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "[DEFAULT]" ] && echo -e "[DEFAULT]\n" > "/etc/fail2ban/jail.local"
        echo -e "action = %(action_)s, %(action_abuseipdb)s\n" >> "/etc/fail2ban/jail.local"

        cat > /etc/fail2ban/action.d/abuseipdb.conf <<EOF
[Definition]

actionban = 
    # Enviar la IP a AbuseIPDB para reportarla
    curl -s -X POST https://api.abuseipdb.com/api/v2/report \
    --header "Key: $F2B_APIKEY" \
    --header "Accept: application/json" \
    --data "ipAddress=<ip>&comment=Fail2Ban%20Report"
EOF
        log "configuraciones para enviar reportes añadida"
    fi

    if [ "$F2B_ABUSEIPDB" == "true" ]; then 
        install_package jq
        [ "$(head -n 1 "/etc/fail2ban/action.d/abuseipdb.conf")" != "[Definition]" ] && echo -e "[Definition]\n" > "/etc/fail2ban/action.d/abuseipdb.conf"

        cat >> /etc/fail2ban/action.d/abuseipdb.conf <<EOF
# Consultar la IP para ver si ya está registrada como maliciosa
ip_info=\$(curl -s -X GET "https://api.abuseipdb.com/api/v2/check?ipAddress=<ip>&maxAgeInDays=90" \
    --header "Key: $F2B_APIKEY" \
    --header "Accept: application/json")

# Extraer el puntaje de abuso de la respuesta de la API
abuse_score=\$(echo "\$ip_info" | jq '.data.abuseConfidenceScore')

# Si el puntaje de abuso es alto (80 o más), baneamos la IP durante 30 días
if [ "\$abuse_score" -ge 80 ]; then
    # Baneamos la IP durante 30 días
    fail2ban-client set <jail_name> banip <ip> 30d
else
    # Si no tiene un puntaje alto, bloqueamos con iptables como de costumbre
    iptables -I f2b_<jail_name> -s <ip> -j REJECT
fi
EOF
    fi
}

fail_recidive() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "\n" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF
[recidive]

enabled  = $F2B_RECIDIVE
bantime  = $F2B_RECBANTIME
findtime = $F2B_RECFINDTIME
maxretry = $F2B_RECMAXRETRY

EOF
    log "jaula de reincidentes añadida"
}

fail_logrotate() {
    install_package wget
    install_package rsyslog

    service_start rsyslog
    service_enable rsyslog

    wget -O /etc/logrotate.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/debian/debian/fail2ban.logrotate

    service_restart rsyslog
    log "rotacion de logs añadida"
}

[[ "$F2B_DEFAULT" == "true" ]] && fail_defaults
[[ -n "$F2B_DEFAULT" ]] && fail_whitelist
[[ "$F2B_BANTIMEINCREMENT" == "true" ]] && fail_increment
[[ "$F2B_SENDREPORTS" == "true" || "$F2B_ABUSEIPDB" == "true" ]] && fail_ipdb
[[ "$F2B_RECIDIVE" == "true" ]] && fail_recidive
[[ "$F2B_LOGROTATE" == "true" ]] && fail_logrotate


# reiniciar servicio fail2ban
service_restart fail2ban





#[[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
#[sshd]
#enabled = true
#port = $SSH_PORT
#action = %(action_)s, %(action_abuseipdb)s[abuseipdb_category="18,22"]



