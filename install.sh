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

ft_die() {
    echo -e "\033[31mERROR:\033[0m $1" >&2
    exit 1
}

# --- Validar archivos obligatorios ---
[[ ! -f "$CONFIG_FILE" ]] && ft_die "Falta config.conf"
[[ ! -f "$UTILS_FILE" ]] && ft_die "Falta lib/utils.sh"

# --- Cargar config y funciones ---
source "$CONFIG_FILE"
source "$UTILS_FILE"

# --- Validar permisos ---
if [[ "$(id -u)" -ne 0 ]]; then
    ft_error_exit "Este script debe ejecutarse como root."
fi

ft_texto_inicio

# --- Comprobar que el sistema es Debian/Ubuntu ---
if ! command -v apt-get >/dev/null; then
    ft_error_exit "Este sistema no utiliza apt-get. Solo se soporta Debian/Ubuntu."
fi

# --- actualizar lista de paquetes ---
apt update

#####################################
#   FUNCION PARA EJECUTAR MODULOS   #
#####################################
ft_run_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/$module_name.sh"
    local enable_var="$2"

    if [[ "${!enable_var}" == "true" ]]; then
        [[ ! -f "$module_file" ]] && ft_error_exit "Falta el módulo $module_name"

        ft_log "$module_name --> Ejecutando módulo"
        source "$module_file"
    else
        ft_log "$module_name DESACTIVADO en config.conf"
    fi
}


################################
#   EJECUCIÓN DE CADA MÓDULO   #
################################

ft_run_module "ssh" ENABLE_SSH
ft_run_module "ddns" ENABLE_DDNS
ft_run_module "ufw" ENABLE_UFW
ft_run_module "fail2ban" ENABLE_FAIL2BAN
ft_run_module "unattended-upgrades" ENABLE_UNATTENDED


ft_texto_fin
exit 0
