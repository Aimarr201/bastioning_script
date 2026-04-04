#!/bin/bash

#################################################
#      Script de configuracion de fail2ban      #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


# validaciones
APIKEY_FILE="/etc/fail2ban/apikey.env"
[[ -f "$APIKEY_FILE" ]] && source "$APIKEY_FILE"

F2B_APIKEY="${F2B_SCRIPT_APIKEY:-${F2B_APIKEY:-}}"

if [[ -n "$F2B_APIKEY" ]]; then
    export F2B_SCRIPT_APIKEY="$F2B_APIKEY"
    [[ -n "${CONFIG_FILE:-}" ]] && replace_or_add "$CONFIG_FILE" "F2B_APIKEY" "\"\""
fi

F2B_APIKEY="${F2B_SCRIPT_APIKEY:-}"

[[ "$F2B_ABUSEIPDB" == "true" && -z "$F2B_APIKEY" ]] && error_exit "F2B_APIKEY no está definido. Escríbelo en config.conf para exportarlo y borrarlo automáticamente"

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
    local abuse_script_src=""

    [[ -z "$F2B_NORESTORE" ]] && F2B_NORESTORE="0"
    mkdir -p /var/log/fail2ban
    touch /var/log/fail2ban/abuseipdb.log

    mkdir -p /etc/fail2ban
    touch "$APIKEY_FILE"
    chmod 600 "$APIKEY_FILE"

    if grep -q "^export F2B_SCRIPT_APIKEY=" "$APIKEY_FILE"; then
        sed -i "s|^export F2B_SCRIPT_APIKEY=.*|export F2B_SCRIPT_APIKEY=$(printf '%q' "$F2B_APIKEY")|" "$APIKEY_FILE"
    else
        echo "export F2B_SCRIPT_APIKEY=$(printf '%q' "$F2B_APIKEY")" >> "$APIKEY_FILE"
    fi

    cat > /etc/fail2ban/abuseipdb.env <<'EOF'
APIKEY_FILE="/etc/fail2ban/apikey.env"
[[ -f "$APIKEY_FILE" ]] && source "$APIKEY_FILE"
ABUSEIPDB_API_KEY="${F2B_SCRIPT_APIKEY:-}"
EOF

    if [[ -n "$BASE_DIR" && -f "$BASE_DIR/resources/abuseipdb-check-report.sh" ]]; then
        abuse_script_src="$BASE_DIR/resources/abuseipdb-check-report.sh"
    elif [[ -f "resources/abuseipdb-check-report.sh" ]]; then
        abuse_script_src="resources/abuseipdb-check-report.sh"
    else
        error_exit "No se encuentra resources/abuseipdb-check-report.sh"
    fi

    cp -r "$abuse_script_src" /usr/local/sbin/abuseipdb-check-report.sh
    chmod 600 /etc/fail2ban/abuseipdb.env
    chmod 755 /var/log/fail2ban/abuseipdb.log
    chmod 755 /usr/local/sbin/abuseipdb-check-report.sh

    install_package curl


    [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "[DEFAULT]" ] && echo -e "[DEFAULT]\n" > "/etc/fail2ban/jail.local"
    cat >> /etc/fail2ban/jail.local <<EOF
action = %(action_)s
         abuseipdb


[highrisk]

enabled  = true
port     = all
logpath  = /dev/null
filter   = sshd-publickey

maxretry = 1
findtime = 1s
bantime  = 30d

action = %(action_)s

EOF

    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "actionban " " /usr/local/sbin/abuseipdb-check-report.sh <ip> <name>"
    replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "norestored " " $F2B_NORESTORE"

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
    if [ "$ENABLE_SSH" == "true" ]; then
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
port     = $SSH_PORT
logpath  = /var/log/auth.log
filter   = sshd-publickey

EOF
    else
        [ "$(head -n 1 "/etc/fail2ban/jail.local")" != "" ] && echo -e "" >> "/etc/fail2ban/jail.local"

        [[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
        cat >> /etc/fail2ban/jail.local <<EOF
[sshd]

enabled  = true
port     = $SSH_PORT

EOF
    fi
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



EOF
    log "jaula para apache añadida"
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

fail_logrotate() {
    install_package wget

    service_start rsyslog
    service_enable rsyslog

    wget -O /etc/logrotate.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/debian/debian/fail2ban.logrotate

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
[[ "$F2B_FTP" == "true" ]] && fail_ftp
[[ "$F2B_POSTFIX" == "true" ]] && fail_postfix
[[ "$F2B_DOVECOT" == "true" ]] && fail_devecot
[[ "$F2B_LOGROTATE" == "true" ]] && fail_logrotate


# reiniciar servicio fail2ban
[[ "$F2B_LOGROTATE" == "true" ]] && service_restart rsyslog
service_restart fail2ban
