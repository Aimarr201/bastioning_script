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

die() {
    echo -e "\033[31mERROR:\033[0m $1" >&2
    exit 1
}

# --- Validar archivos obligatorios ---
[[ ! -f "$CONFIG_FILE" ]] && die "Falta config.conf"
[[ ! -f "$UTILS_FILE" ]] && die "Falta lib/utils.sh"

# --- Cargar config y funciones ---
source "$CONFIG_FILE"
source "$UTILS_FILE"

# --- Gestion de secretos en variables de entorno ---
mkdir -p /etc/bastioning
touch "$SECRETS_FILE"
chmod 600 "$SECRETS_FILE"

set_secret_env() {
    local key_name="$1"
    local key_value="$2"
    local escaped_value=""

    escaped_value=$(printf '%q' "$key_value")

    if grep -q "^export ${key_name}=" "$SECRETS_FILE"; then
        sed -i "s|^export ${key_name}=.*|export ${key_name}=${escaped_value}|" "$SECRETS_FILE"
    else
        echo "export ${key_name}=${escaped_value}" >> "$SECRETS_FILE"
    fi
}

clear_config_secret() {
    local key_name="$1"
    sed -i "s|^[[:space:]]*${key_name}=.*|    ${key_name}=\"\"|" "$CONFIG_FILE"
}

# Prioriza variables de entorno del sistema y conserva compatibilidad con config en esta ejecucion.
if [[ -n "${DDNS_APIKEY:-}" ]]; then
    export DDNS_SCRIPT_APIKEY="$DDNS_APIKEY"
    set_secret_env "DDNS_SCRIPT_APIKEY" "$DDNS_SCRIPT_APIKEY"
fi

if [[ -n "${F2B_APIKEY:-}" ]]; then
    export F2B_SCRIPT_APIKEY="$F2B_APIKEY"
    set_secret_env "F2B_SCRIPT_APIKEY" "$F2B_SCRIPT_APIKEY"
fi

# Limpia cualquier API key que se haya dejado en config.conf.
clear_config_secret "DDNS_APIKEY"
clear_config_secret "F2B_APIKEY"

# --- Validar permisos ---
if [[ "$(id -u)" -ne 0 ]]; then
    error_exit "Este script debe ejecutarse como root."
fi

texto_inicio

# --- Comprobar que el sistema es Debian/Ubuntu ---
if ! command -v apt-get >/dev/null; then
    error_exit "Este sistema no utiliza apt-get. Solo se soporta Debian/Ubuntu."
fi

# --- actualizar lista de paquetes ---
apt update

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
run_module "ufw" ENABLE_UFW
run_module "fail2ban" ENABLE_FAIL2BAN
run_module "unattended-upgrades" ENABLE_UNATTENDED


texto_fin
exit 0
