#!/bin/bash

#################################################
#      Script de configuracion de fail2ban      #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


# validaciones
[[ "$F2B_ABUSEIPDB" == "true" && -z "$F2B_APIKEY" ]] && error_exit "F2B_APIKEY no está definido en config.conf"

# instalar paquetes
install_package fail2ban
install_package rsyslog

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
    mkdir /var/log/fail2ban
    touch /var/log/fail2ban/abuseipdb.log
    cp resources/abuseipdb-check-report.sh /usr/local/sbin/abuseipdb-check-report.sh
    chmod 755 /var/log/fail2ban/abuseipdb.log
    chmod 755 /usr/local/sbin/abuseipdb-check-report.sh

    install_package curl

    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "[DEFAULT]" ] && echo -e "[DEFAULT]\n" > "/etc/fail2ban/jail.local"
    cat >> /etc/fail2ban/jail.local <<EOF
action = %(action_)s
         %(action_abuseipdb)s

EOF

    replace_or_add "/usr/local/sbin/abuseipdb-check-report.sh" "API_KEY" "\"$F2B_APIKEY\""

    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "norestored " " 0"
    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "actionban " " /usr/local/sbin/abuseipdb-check-report.sh <ip> <jail>"
    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "abuseipdb_apikey " " $F2B_APIKEY"
    log "Reportes con AbuseIPDB añadido"
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

    service_start rsyslog
    service_enable rsyslog

    wget -O /etc/logrotate.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/debian/debian/fail2ban.logrotate

    service_restart rsyslog
    log "rotacion de logs añadida"
}

[[ "$F2B_DEFAULT" == "true" ]] && fail_defaults
[[ -n "$F2B_WHITELIST" ]] && fail_whitelist
[[ "$F2B_BANTIMEINCREMENT" == "true" ]] && fail_increment
[[ "$F2B_ABUSEIPDB" == "true" ]] && fail_ipdb
[[ "$F2B_RECIDIVE" == "true" ]] && fail_recidive
[[ "$F2B_LOGROTATE" == "true" ]] && fail_logrotate


# reiniciar servicio fail2ban
service_restart fail2ban





#[[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
#[sshd]
#enabled = true
#port = $SSH_PORT



