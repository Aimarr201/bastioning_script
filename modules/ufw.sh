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

# establecer reglas de entrada por defecto
[[ "$UFW_DAIT" == "true" ]] && sudo ufw default deny incoming comment "deny all incoming traffic" && log "regala para denegar todo el trafico entrante por defecto añadida"

# establecer reglas de entrada especificas
[[ "$UFW_ISSH" == "true" && -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
[[ "$UFW_ISSH" == "true" ]] && sudo ufw allow in "$SSH_PORT"/tcp comment "allow SSH incoming connections on port $SSH_PORT" && log "regala para ssh por el puerto $SSH_PORT añadida"

[[ "$UFW_IDNS" == "true" ]] && sudo ufw allow in 53/udp comment "allow DNS calls in" && log "regala de entrada DNS añadida"

[[ "$UFW_INTP" == "true" ]] && sudo ufw allow in 53/udp comment "allow DNS calls in" && log "regala de entrada DNS añadida"

[[ "$UFW_IHTTP" == "true" ]] && sudo ufw allow in http comment "allow HTTP traffic in" && log "regala de entrada HTTP añadida"

[[ "$UFW_IHTTPS" == "true" ]] && sudo ufw allow in https comment "allow HTTPS traffic in" && log "regala de entrada HTTPS añadida"

[[ "$UFW_IFTP" == "true" ]] && sudo ufw allow in ftp comment "allow FTP traffic in" && log "regala de entrada FTP añadida"

[[ "$UFW_IICMP" == "true" ]] && sudo ufw allow in icmp comment "allow ICMP in" && log "regala de entrada ICMP añadida"

[[ "$UFW_ISMTP" == "true" ]] && sudo ufw allow in 25 comment "allow SMTP in" && sudo ufw allow in 587 comment "allow SMTP in" && log "regala de entrada SMTP añadida"

[[ "$UFW_IDHCP" == "true" ]] && sudo ufw allow in 67 comment "allow DHCP in" && sudo ufw allow in 68 comment "allow DHCP in"  && log "regala de entrada DHCP añadida"


# establecer reglas de salida por defecto
[[ "$UFW_DAOT" == "true" ]] && sudo ufw default deny outgoing comment "deny all outgoing traffic" && log "regala para denegar todo el trafico saliente por defecto añadida"
[[ "$UFW_DAOT" == "false" ]] && sudo ufw default allow outgoing comment "allow all outgoing traffic" && log "regala para permitir todo el trafico saliente por defecto añadida"

# establecer reglas de salida especificas
[[ "$UFW_OSSH" == "true" ]] && sudo ufw allow in 22/tcp comment "allow SSH outgoing connections on port 22" && log "regala para ssh saliente por el puerto 22 añadida"

[[ "$UFW_ODNS" == "true" ]] && sudo ufw allow out 53 comment "allow DNS calls out" && log "regala de salida DNS añadida"

[[ "$UFW_ONTP" == "true" ]] && sudo ufw allow out 123 comment "allow NTP out" && log "regala de salida NTP añadida"

[[ "$UFW_OHTTP" == "true" ]] && sudo ufw allow out http comment "allow HTTP traffic out" && log "regala de salida HTTP añadida"

[[ "$UFW_OHTTPS" == "true" ]] && sudo ufw allow out https comment "allow HTTPS traffic out" && log "regala de salida HTTPS añadida"

[[ "$UFW_OFTP" == "true" ]] && sudo ufw allow out ftp comment "allow FTP traffic out" && log "regala de salida FTP añadida"

[[ "$UFW_OSMTP" == "true" ]] && sudo ufw allow out 25 comment "allow SMTP out" && sudo ufw allow out 587 comment "allow SMTP out" && log "regala de salida SMTP añadida"

[[ "$UFW_ODHCP" == "true" ]] && sudo ufw allow out 67 comment "allow the DHCP client to update" && sudo ufw allow out 68 comment "allow the DHCP client to update"  && log "regala de salida DHCP añadida"

[[ "$UFW_OICMP" == "true" ]] && sudo ufw allow out icmp comment "allow ICMP out" && log "regala de salida ICMP añadida"

# habilitar ufw
echo  "y" | sudo ufw enable && log "ufw habilitado"
log "ufw configurado correctamente"