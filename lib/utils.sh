#!/bin/bash

#################################################
#               Funciones comunes               #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


LOGFILE="/var/log/bastion.log"

log() {
    echo -e "\033[32mLOG:\033[0m [$(date '+%T')] $1"
    echo "[$(date '+%F %T')] $1" >> "$LOGFILE"
}

install_package() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        log "Instalando paquete: $1"
        apt-get install -y -qq "$1"
    else
        log "Paquete $1 ya instalado"
    fi
}

backup_file() {
    local file=$1
    [[ -f "$file" ]] && cp "$file" "$file.bak_$(date +%F_%T)" && log "Backup: $file"
}

replace_or_add() {
    local file="$1"
    local key="$2"
    local value="$3"

    grep -q "^$key" "$file" && \
        sed -i "s|^$key.*|$key = $value|" "$file" || \
        echo "$key = $value" >> "$file"

    log "Config: $key $value -> $file"
}

service_restart() {
    systemctl restart "$1"
    log "Servicio $1 reiniciado."
}

service_enable() {
    systemctl enable "$1"
    log "Servicio $1 habilitado."
}

service_start() {
    systemctl start "$1"
    log "Servicio $1 iniciado."
}

add_cronjob() {
    local job="$1"
    (crontab -l 2>/dev/null | grep -Fv "$job" ; echo "$job") | crontab -
    log "Cron añadido: $job"
}

error_exit() {
    echo -e "\033[31mERROR:\033[0m $1" >&2
    log "ERROR: $1"
    exit 1
}

texto_inicio() {
    log "  ___       _      _              _      _              _            _   "
    log " |_ _|_ __ (_) ___(_) ___      __| | ___| |    ___  ___(_)_ __ _ __ | |_ "
    log "  | || '_ \| |/ __| |/ _ \    / _' |/ _ \ |   / __|/ __| | '__| '_ \| __|"
    log "  | || | | | | (__| | (_) |  | (_| |  __/ |   \__ \ (__| | |  | |_) | |_ "
    log " |___|_| |_|_|\___|_|\___/    \__,_|\___|_|   |___/\___|_|_|  | .__/ \__|"
    log "                                                              |_|        "
}

texto_fin() {
    log " _           _        _            _                         _ _                  "
    log "(_)_ __  ___| |_ __ _| | __ _  ___(_) ___  _ __     _____  _(_) |_ ___  ___  __ _ "
    log "| | '_ \/ __| __/ _' | |/ _' |/ __| |/ _ \| '_ \   / _ \ \/ / | __/ _ \/ __|/ _' |"
    log "| | | | \__ \ || (_| | | (_| | (__| | (_) | | | | |  __/>  <| | || (_) \__ \ (_| |"
    log "|_|_| |_|___/\__\__,_|_|\__,_|\___|_|\___/|_| |_|  \___/_/\_\_|\__\___/|___/\__,_|"

}