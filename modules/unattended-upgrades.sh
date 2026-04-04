#!/bin/bash

#################################################
#    Script para actualizaciones automaticas    #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


ft_log "Configurando unattended-upgrades"

# validaciones
[[ -z "$UNATT_ENABLE" ]] && ft_error_exit "UNATT_ENABLE no está definido en config.conf"
[[ -z "$UNATT_UPDATEDAYS" ]] && ft_error_exit "UNATT_UPDATEDAYS no está definido en config.conf"
[[ -z "$UNATT_DOWNLOADDAYS" ]] && ft_error_exit "UNATT_DOWNLOADDAYS no está definido en config.conf"
[[ -z "$UNATT_AUTOCLEAN" ]] && ft_error_exit "UNATT_AUTOCLEAN no está definido en config.conf"
[[ -z "$UNATT_AUTOUPGRADE" ]] && ft_error_exit "UNATT_AUTOUPGRADE no está definido en config.conf"
[[ -z "$UNATT_DPKG" ]] && ft_error_exit "UNATT_DPKG no está definido en config.conf"
[[ -z "$UNATT_INSTALLONSHUTDOWN" ]] && ft_error_exit "UNATT_INSTALLONSHUTDOWN no está definido en config.conf"
[[ -z "$UNATT_REMOVEUNUSED" ]] && ft_error_exit "UNATT_REMOVEUNUSED no está definido en config.conf"
[[ -z "$UNATT_REMOVENEWUNUSED" ]] && ft_error_exit "UNATT_REMOVENEWUNUSED no está definido en config.conf"
[[ -z "$UNATT_REBOOT" ]] && ft_error_exit "UNATT_REBOOT no está definido en config.conf"
[[ -z "$UNATT_REBOOTWITHUSERS" ]] && ft_error_exit "UNATT_REBOOTWITHUSERS no está definido en config.conf"

# definir rutas
SOURCES_LIST="/etc/apt/sources.list"
SOURCES_DIR="/etc/apt/sources.list.d/"

# comprobar si hay que cambiar repositorios http por https
if [[ "$UNATT_SOURCES" == "true" ]]; then
    [[ -f "$SOURCES_LIST" ]] && sed -i 's|http://|https://|g' "$SOURCES_LIST"

    for file in "$SOURCES_DIR"*.list; do
        [[ -f "$file" ]] || continue
        sed -i 's|http://|https://|g' "$file"
    done
fi

# instalar paquetes
ft_install_package "unattended-upgrades"
ft_install_package "apt-listchanges"

# crear archivo de configuración
ft_backup_file "/etc/apt/apt.conf.d/51myunattended-upgrades"
cat > /etc/apt/apt.conf.d/51myunattended-upgrades <<EOF

// Activa el sistema de actualizaciones automáticas periódicas.
APT::Periodic::Enable "$UNATT_ENABLE";

// Ejecuta automáticamente 'apt-get update' cada n días para actualizar
// la lista de paquetes disponibles desde los repositorios.
APT::Periodic::Update-Package-Lists "$UNATT_UPDATEDAYS";

// Ejecuta 'apt-get upgrade --download-only' cada n días para
// descargar paquetes actualizables sin instalarlos todavía.
APT::Periodic::Download-Upgradeable-Packages "$UNATT_DOWNLOADDAYS";

// Ejecuta 'apt-get autoclean' cada n días para eliminar archivos de
// paquetes '.deb' antiguos que ya no están disponibles para su descarga.
APT::Periodic::AutocleanInterval "$UNATT_AUTOCLEAN";

// Activa la instalación automática de actualizaciones sin intervención del usuario.
// "1" activa las actualizaciones automáticas.
APT::Periodic::Unattended-Upgrade "$UNATT_AUTOUPGRADE";
EOF
cat >> /etc/apt/apt.conf.d/51myunattended-upgrades <<'EOF'

// Define qué repositorios están permitidos para aplicar
// actualizaciones automáticas. Aquí se permiten:
// - Repositorio principal de Debian estable
// - Actualizaciones importantes de Debian estable
// - Actualizaciones de seguridad específicas del sistema
Unattended-Upgrade::Origins-Pattern {
      "o=Debian,a=stable";
      "o=Debian,a=stable-updates";
      "origin=Debian,codename=${distro_codename},label=Debian-Security";
};

// Lista de paquetes que NO deben ser actualizados automáticamente.
Unattended-Upgrade::Package-Blacklist {
};
EOF
cat >> /etc/apt/apt.conf.d/51myunattended-upgrades <<EOF

// Si se detecta un estado no limpio de dpkg, se asegura que las actualizaciones
// se instalen incluso si el sistema fue interrumpido durante una ejecución anterior.
Unattended-Upgrade::AutoFixInterruptedDpkg "$UNATT_DPKG";

// Ejecuta las actualizaciones aunque el sistema esté encendido y en uso.
Unattended-Upgrade::InstallOnShutdown "$UNATT_INSTALLONSHUTDOWN";

// Después de instalar actualizaciones, elimina dependencias antiguas.
Unattended-Upgrade::Remove-Unused-Dependencies "$UNATT_REMOVEUNUSED";

// Eliminar cualquier nueva dependencia no utilizada.
Unattended-Upgrade::Remove-New-Unused-Dependencies "$UNATT_REMOVENEWUNUSED";

// Si después de una actualización detecta que el sistema necesita reiniciarse,
// se reiniciará automáticamente sin preguntar ni esperar confirmación.
Unattended-Upgrade::Automatic-Reboot "$UNATT_REBOOT";

// Permite que el sistema se reinicie automáticamente incluso si hay
// usuarios conectados. Puede cerrar sesiones activas sin aviso.
Unattended-Upgrade::Automatic-Reboot-WithUsers "$UNATT_REBOOTWITHUSERS";
EOF

# comprobación de configuración correcta

if ! unattended-upgrade -d --dry-run; then
    LOG_FILE="/var/log/unattended-upgrades/unattended-upgrades.log"
    if [[ -f "$LOG_FILE" ]]; then
        ft_log "Últimas líneas del log de unattended-upgrades tras error:"
        while IFS= read -r line; do
            ft_log "$line"
        done < <(tail -n 40 "$LOG_FILE")
    fi
    ft_error_exit "Error en la comprobación de unattended-upgrades (dry-run)"
fi

ft_log "unattended-upgrades configurado correctamente"
