#!/bin/bash

#################################################
#       Script para la instalacion de ufw       #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


# validaciones
[[ -z "$UFW_DAOT" ]] && error_exit "UFW_DAOT no está definido en config.conf"
[[ -z "$UFW_DAIT" ]] && error_exit "UFW_DAIT no está definido en config.conf"

# instalar paquetes
install_package ufw

# establecer reglas por defecto
[[ "$UFW_DAOT" == "true" ]] && sudo ufw default deny outgoing comment "deny all outgoing traffic" && log "regala para denegar todo el trafico saliente por defecto añadida"
[[ "$UFW_DAOT" == "false" ]] && sudo ufw default allow outgoing comment "allow all outgoing traffic" && log "regala para permitir todo el trafico saliente por defecto añadida"

[[ "$UFW_DAIT" == "true" ]] && sudo ufw default deny incoming comment "deny all incoming traffic" && log "regala para denegar todo el trafico entrante por defecto añadida"

# establecer reglas especificas
[[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
[[ "$UFW_SSH" == "true" ]] && sudo ufw limit in "$SSH_PORT"/tcp comment "allow SSH connections on port $SSH_PORT" && log "regala para ssh por el puerto $SSH_PORT añadida"

[[ "$UFW_DNS" == "true" ]] && sudo ufw allow out 53 comment "allow DNS calls out" && log "regala de salida DNS añadida"

[[ "$UFW_NTP" == "true" ]] && sudo ufw allow out 123 comment "allow NTP out" && log "regala de salida NTP añadida"

[[ "$UFW_HTTP" == "true" ]] && sudo ufw allow out http comment "allow HTTP traffic out" && log "regala de salida HTTP añadida"

[[ "$UFW_HTTPS" == "true" ]] && sudo ufw allow out https comment "allow HTTPS traffic out" && log "regala de salida HTTPS añadida"

[[ "$UFW_FTP" == "true" ]] && sudo ufw allow out ftp comment "allow FTP traffic out" && log "regala de salida FTP añadida"

[[ "$UFW_WHOIS" == "true" ]] && sudo ufw allow out whois comment "allow whois" && log "regala de salida whois añadida"

[[ "$UFW_SMTP" == "true" ]] && sudo ufw allow out 25 comment "allow SMTP out" && sudo ufw allow out 587 comment "allow SMTP out" && log "regala de salida SMTP añadida"

[[ "$UFW_DHCP" == "true" ]] && sudo ufw allow out 67 comment "allow the DHCP client to update" && sudo ufw allow out 68 comment "allow the DHCP client to update"  && log "regala de salida DHCP añadida"

# habilitar ufw
echo  "y" | sudo ufw enable && log "ufw habilitado"
log "ufw configurado correctamente"