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
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]

EOF

fail_defaults() {
cat >> /etc/fail2ban/jail.local <<EOF
bantime  = $F2B_DEFBANTIME
findtime = $F2B_DEFFINDTIME
maxretry = $F2B_DEFMAXRETRY

EOF
}

fail_whitelist() {
cat >> /etc/fail2ban/jail.local <<EOF
ignoreip = $F2B_WHITELIST

EOF
}

fail_increment() {
cat >> /etc/fail2ban/jail.local <<EOF
bantime.increment    = $F2B_BANTIMEINCREMENT
bantime.rndtime      = $F2B_RNDTIME
bantime.maxtime      = $F2B_MAXTIME
bantime.factor       = $F2B_FACTOR
bantime.overalljails = $F2B_OVERALL

EOF
}

fail_recidive() {
cat >> /etc/fail2ban/jail.local <<EOF

[recidive]

enabled  = $F2B_RECIDIVE
bantime  = $F2B_RECBANTIME
findtime = $F2B_RECFINDTIME
maxretry = $F2B_RECMAXRETRY

EOF
}

sendrp() {
    install_package curl
    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "abuseipdb_apikey" "$F2B_APIKEY"
    systemctl restart rsyslog
}

logrotate() {
    install_package wget
    install_package rsyslog

    service_start rsyslog
    service_enable rsyslog

    wget -O /etc/logrotate.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/debian/debian/fail2ban.logrotate

    service_restart rsyslog

}

ipdb() {
    .
}

[[ "$F2B_SENDREPORTS" == "true" ]] && sendrp && log "configuraciones para enviar reportes añadida"
[[ "$F2B_DEFAULT" == "true" ]] && fail_defaults && log "configuraciones para jaulas default añadida" # mover los logs exitosos a cada funcion
[[ -n "$F2B_DEFAULT" ]] && fail_whitelist && log "direcciones ip permitidas añadidas a la lista blanca"
[[ "$F2B_BANTIMEINCREMENT" == "true" ]] && fail_increment && log "incremento de tiempo de bloqueo añadido"
[[ "$F2B_RECIDIVE" == "true" ]] && fail_recidive && log "jaula de reincidentes añadida"
ipdb
[[ "$F2B_LOGROTATE" == "true" ]] && logrotate && log "rotacion de logs añadida"


# reiniciar servicio fail2ban
service_restart fail2ban




[sshd]
enabled = true