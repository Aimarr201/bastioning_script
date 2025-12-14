#!/bin/bash

#################################################
#  Script principal de instalación del sistema  #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################

# --- Validar permisos ---
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# --- Rutas importantes ---
BASE_DIR="$(dirname "$0")"
CONFIG_FILE="$BASE_DIR/config.conf"
UTILS_FILE="$BASE_DIR/lib/utils.sh"
MODULES_DIR="$BASE_DIR/modules"

# --- Validar archivos obligatorios ---
[[ ! -f "$CONFIG_FILE" ]] && { echo "ERROR: Falta config.conf"; exit 1; }
[[ ! -f "$UTILS_FILE" ]]  && { echo "ERROR: Falta lib/utils.sh"; exit 1; }

# --- Cargar config y funciones ---
source "$CONFIG_FILE"
source "$UTILS_FILE"

log "=== INICIO DE INSTALACIÓN DEL SISTEMA DE BASTIONADO ==="

# --- Comprobar que el sistema es Debian/Ubuntu ---
if ! command -v apt-get >/dev/null; then
    error_exit "Este sistema no utiliza apt-get. Solo se soportan Debian/Ubuntu."
fi

install_package "curl"
install_package "jq"
install_package "cron"


###################################
#  FUNCION PARA EJECUTAR MODULOS  #
###################################
run_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/$module_name.sh"
    local enable_var="$2"

    if [[ "${!enable_var}" == "true" ]]; then
        [[ ! -f "$module_file" ]] && error_exit "Falta el módulo $module_name"

        log "--- Ejecutando módulo: $module_name ---"
        source "$module_file"
    else
        log "Módulo $module_name desactivado en config.conf"
    fi
}


################################
#   EJECUCIÓN DE CADA MÓDULO   #
################################

run_module "ssh"          ENABLE_SSH
run_module "ddns"         ENABLE_DDNS
run_module "iptables"     ENABLE_IPTABLES
run_module "fail2ban"     ENABLE_FAIL2BAN
run_module "unattended"   ENABLE_UNATTENDED


log "=== INSTALACIÓN COMPLETADA CON ÉXITO ==="
exit 0
