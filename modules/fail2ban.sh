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
backup_file /etc/fail2ban/jail.local
touch /etc/fail2ban/jail.local

# funciones para la configuracion de jail.local
fail_defaults() {
    cat > /etc/fail2ban/jail.local <<EOF
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
    [[ -z "$F2B_NORESTORE" ]] && F2B_NORESTORE="0"
    mkdir /var/log/fail2ban
    touch /var/log/fail2ban/abuseipdb.log
    cp resources/abuseipdb-check-report.sh /usr/local/sbin/abuseipdb-check-report.sh
    chmod +x /usr/local/sbin/abuseipdb-check-report.sh
    chmod 755 /var/log/fail2ban/abuseipdb.log
    chmod 755 /usr/local/sbin/abuseipdb-check-report.sh

    install_package curl

    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "[DEFAULT]" ] && echo -e "[DEFAULT]\n" > "/etc/fail2ban/jail.local"
    cat >> /etc/fail2ban/jail.local <<EOF
action = %(action_abuseipdb)s

EOF

    replace_or_add "/usr/local/sbin/abuseipdb-check-report.sh" "API_KEY" "\"$F2B_APIKEY\""

    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "norestored " " $F2B_NORESTORE"
    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "actionban " " /usr/local/sbin/abuseipdb-check-report.sh <ip> <jail>"
    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "abuseipdb_apikey " " $F2B_APIKEY"

    log "Reportes con AbuseIPDB añadido"
}

fail_recidive() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF
[recidive]

enabled  = $F2B_RECIDIVE
bantime  = $F2B_RECBANTIME
findtime = $F2B_RECFINDTIME
maxretry = $F2B_RECMAXRETRY

EOF
    log "jaula de reincidentes añadida"
}

fail_sshd() {
    cat >   /etc/fail2ban/filter.d/sshd-publickey.conf <<EOF
# Filtro para detectar rechazos de publickey SSH
[Definition]

failregex = ^.*sshd.*Connection (?:reset|closed) by authenticating user .* <HOST> port \d+.*$
            ^.*sshd.*Disconnected from authenticating user .* <HOST>.*$
            ^.*sshd.*Connection reset by <HOST> \[preauth\]$

ignoreregex =
EOF
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    [[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
    cat >> /etc/fail2ban/jail.local <<EOF
[sshd-publickey]

enabled  = true
port     = 60696
logpath  = /var/log/auth.log
filter   = sshd-publickey

EOF
    log "jaula para sshd añadida"
}

fail_nginx() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF
[nginx-http-auth]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log


[nginx-limit-req]
enabled  = false
port     = http,https
logpath  = /var/log/nginx/error.log


[nginx-botsearch]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/access.log
maxretry = 2
findtime = 10m
bantime  = 24h

EOF
    log "jaula para nginx añadida"
}

fail_apache() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF

[apache-auth]
enabled  = true
port     = http,https
logpath  = /var/log/apache2/error.log


[apache-limit-req]
enabled  = true
port     = http,https
logpath  = /var/log/apache2/access.log

EOF
    log "jaula para apache añadida"
}

fail_wordpress() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF

[wordpress-hard]
enabled  = true
port     = http,https
logpath  = /var/log/wordpress/auth.log
maxretry = 3
findtime = 10m
bantime  = 24h


[wordpress-xmlrpc]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/access.log
maxretry = 5
findtime = 10m
bantime  = 24h

EOF
    log "jaula para wordpress añadida"
}

fail_ftp() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF

[vsftpd]
enabled  = true
port     = ftp
logpath  = /var/log/vsftpd.log
maxretry = 5
findtime = 10m
bantime  = 24h

EOF
    log "jaula para ftp añadida"
}

fail_postfix() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF

[postfix]
enabled  = true
port     = smtp
logpath  = /var/log/mail.log
maxretry = 5
findtime = 10m
bantime  = 1h


[postfix-sasl]
enabled  = true
port     = smtp,imap,pop3
logpath  = /var/log/mail.log
maxretry = 3
findtime = 10m
bantime  = 24h


EOF
    log "jaula para postfix añadida"
}

fail_devecot() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    cat >> /etc/fail2ban/jail.local <<EOF

[dovecot]
enabled  = true
port     = imap,pop3
logpath  = /var/log/mail.log
maxretry = 5
findtime = 10m
bantime  = 1h

EOF
    log "jaula para devecot añadida"
}

fail_custom() {
    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

    [[ -z "$F2B_CUSTOM_MAX" ]] && F2B_CUSTOM_MAX="$F2B_DEFMAXRETRY"
    [[ -z "$F2B_CUSTOM_FIND" ]] && F2B_CUSTOM_FIND="$F2B_DEFFINDTIME"
    [[ -z "$F2B_CUSTOM_BAN" ]] && F2B_CUSTOM_BAN="$F2B_DEFBANTIME"

    cat >> /etc/fail2ban/jail.local <<EOF
[$F2B_CUSTOM_NAME]
enabled  = true
port     = $F2B_CUSTOM_PORT
logpath  = $F2B_CUSTOM_LOG
maxretry = $F2B_CUSTOM_MAX
findtime = $F2B_CUSTOM_FIND
bantime  = $F2B_CUSTOM_BAN

EOF
    log "jaula para $F2B_CUSTOM_NAME añadida"
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
[[ "$F2B_SSHD" == "true" ]] && fail_sshd
[[ "$F2B_NGINX" == "true" ]] && fail_nginx
[[ "$F2B_APACHE" == "true" ]] && fail_apache
[[ "$F2B_WORDPRESS" == "true" ]] && fail_wordpress
[[ "$F2B_FTP" == "true" ]] && fail_ftp
[[ "$F2B_POSTFIX" == "true" ]] && fail_postfix
[[ "$F2B_DOVECOT" == "true" ]] && fail_devecot
[[ "$F2B_CUSTOM" == "true" ]] && fail_custom
[[ "$F2B_LOGROTATE" == "true" ]] && fail_logrotate


# reiniciar servicio fail2ban
service_restart fail2ban


