#!/bin/bash

#################################################
#       Script para la instalacion de ufw       #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


[[ -z "$UFW_DAOT" ]] && error_exit "UFW_DAOT no está definido en config.conf"
[[ -z "$UFW_DAIT" ]] && error_exit "UFW_DAIT no está definido en config.conf"

install_package ufw

[[ "$UFW_DAOT" == "true" ]] && sudo ufw default deny outgoing comment "deny all outgoing traffic"
[[ "$UFW_DAOT" == "false" ]] && sudo ufw default allow outgoing comment "allow all outgoing traffic"

[[ "$UFW_DAIT" == "true" ]] && sudo ufw default deny incoming comment "deny all incoming traffic" # si es false este bloque se podria saltar


[[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
[[ "$UFW_SSH" == "true" ]] && sudo ufw limit in "$SSH_PORT"/tcp comment "allow SSH connections on port $SSH_PORT"

[[ "$UFW_DNS" == "true" ]] && sudo ufw allow out 53 comment "allow DNS calls out"

[[ "$UFW_NTP" == "true" ]] && sudo ufw allow out 123 comment "allow NTP out"

[[ "$UFW_HTTP" == "true" ]] && sudo ufw allow out http comment "allow HTTP traffic out"

[[ "$UFW_HTTPS" == "true" ]] && sudo ufw allow out https comment "allow HTTPS traffic out"

[[ "$UFW_FTP" == "true" ]] && sudo ufw allow out ftp comment "allow FTP traffic out"

[[ "$UFW_WHOIS" == "true" ]] && sudo ufw allow out whois comment "allow whois"

[[ "$UFW_SMTP" == "true" ]] && sudo ufw allow out 25 comment "allow SMTP out" && sudo ufw allow out 587 comment "allow SMTP out"

[[ "$UFW_DHCP" == "true" ]] && sudo ufw allow out 67 comment "allow the DHCP client to update" && sudo ufw allow out 68 comment "allow the DHCP client to update"

echo  "y" | sudo ufw enable
