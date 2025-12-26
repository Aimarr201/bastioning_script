#!/bin/bash

#################################################
#  Script principal de instalación del sistema  #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


# --- Rutas importantes ---
BASE_DIR="$(dirname "$0")"
CONFIG_FILE="$BASE_DIR/config.conf"
UTILS_FILE="$BASE_DIR/lib/utils.sh"
MODULES_DIR="$BASE_DIR/modules"

# --- Validar permisos ---
if [[ "$(id -u)" -ne 0 ]]; then
    error_exit "Este script debe ejecutarse como root."
fi

# --- Validar archivos obligatorios ---
[[ ! -f "$CONFIG_FILE" ]] && { error_exit "Falta config.conf"; }
[[ ! -f "$UTILS_FILE" ]]  && { error_exit "Falta lib/utils.sh"; }

# --- Cargar config y funciones ---
source "$CONFIG_FILE"
source "$UTILS_FILE"

texto_inicio

# --- Comprobar que el sistema es Debian/Ubuntu ---
if ! command -v apt-get >/dev/null; then
    error_exit "Este sistema no utiliza apt-get. Solo se soporta Debian/Ubuntu."
fi


#####################################
#   FUNCION PARA EJECUTAR MODULOS   #
#####################################
run_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/$module_name.sh"
    local enable_var="$2"

    if [[ "${!enable_var}" == "true" ]]; then
        [[ ! -f "$module_file" ]] && error_exit "Falta el módulo $module_name"

        log "$module_name --> Ejecutando módulo"
        source "$module_file"
    else
        log "$module_name DESACTIVADO en config.conf"
    fi
}


################################
#   EJECUCIÓN DE CADA MÓDULO   #
################################

run_module "ssh" ENABLE_SSH
run_module "ddns" ENABLE_DDNS
run_module "iptables" ENABLE_IPTABLES
run_module "fail2ban" ENABLE_FAIL2BAN
run_module "unattended-upgrades" ENABLE_UNATTENDED


texto_fin
exit 0
