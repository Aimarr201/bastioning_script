#!/bin/bash

#################################################
#               Funciones comunes               #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


LOGFILE="/var/log/bastion.log"

ft_log() {
    echo -e "\033[32mLOG:\033[0m [$(date '+%T')] $1"
    echo "[$(date '+%F %T')] $1" >> "$LOGFILE"
}

ft_install_package() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        ft_log "Instalando paquete: $1"
        apt-get install -y -qq "$1"
    else
        ft_log "Paquete $1 ya instalado"
    fi
}

ft_backup_file() {
    local file=$1
    [[ -f "$file" ]] && cp "$file" "$file.bak_$(date +%F_%T)" && ft_log "Backup: $file"
}

ft_replace_or_add() {
    local file="$1"
    local key="$2"
    local value="$3"

    grep -Eq "^[[:space:]]*${key}" "$file" && \
        sed -i -E "s|^[[:space:]]*(${key}).*|\1=${value}|" "$file" || \
        echo "$key=$value" >> "$file"

    ft_log "Config: $key $value -> $file"
}

ft_service_restart() {
    systemctl restart "$1"
    ft_log "Servicio $1 reiniciado."
}

ft_service_enable() {
    systemctl enable "$1"
    ft_log "Servicio $1 habilitado."
}

ft_service_start() {
    systemctl start "$1"
    ft_log "Servicio $1 iniciado."
}

ft_add_cronjob() {
    local job="$1"
    (crontab -l 2>/dev/null | grep -Fv "$job" ; echo "$job") | crontab -
    ft_log "Cron añadido: $job"
}

ft_error_exit() {
    echo -e "\033[31mERROR:\033[0m $1" >&2
    ft_log "ERROR: $1"
    exit 1
}

ft_texto_inicio() {
    ft_log "  ___       _      _              _      _              _            _   "
    ft_log " |_ _|_ __ (_) ___(_) ___      __| | ___| |    ___  ___(_)_ __ _ __ | |_ "
    ft_log "  | || '_ \| |/ __| |/ _ \    / _' |/ _ \ |   / __|/ __| | '__| '_ \| __|"
    ft_log "  | || | | | | (__| | (_) |  | (_| |  __/ |   \__ \ (__| | |  | |_) | |_ "
    ft_log " |___|_| |_|_|\___|_|\___/    \__,_|\___|_|   |___/\___|_|_|  | .__/ \__|"
    ft_log "                                                              |_|        "
}

ft_texto_fin() {
    ft_log " _           _        _            _                         _ _                  "
    ft_log "(_)_ __  ___| |_ __ _| | __ _  ___(_) ___  _ __     _____  _(_) |_ ___  ___  __ _ "
    ft_log "| | '_ \/ __| __/ _' | |/ _' |/ __| |/ _ \| '_ \   / _ \ \/ / | __/ _ \/ __|/ _' |"
    ft_log "| | | | \__ \ || (_| | | (_| | (__| | (_) | | | | |  __/>  <| | || (_) \__ \ (_| |"
    ft_log "|_|_| |_|___/\__\__,_|_|\__,_|\___|_|\___/|_| |_|  \___/_/\_\_|\__\___/|___/\__,_|"

}