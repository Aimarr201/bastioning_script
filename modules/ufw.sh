#!/bin/bash

#################################################
#       Script para la instalacion de ufw       #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################


install_package ufw

UFW_DAOT true ufw default deny outgoing comment 'deny all outgoing traffic'
UFW_DAOT false ufw default allow outgoing comment 'allow all outgoing traffic'

UFW_DAIT true sudo ufw default deny incoming comment 'deny all incoming traffic'

[[ -z "$SSH_PORT" ]] && SSH_PORT="22" && log "SSH_PORT no está definido en config.conf. Se le asigna el valor por defecto (22)"
UFW_SSH true ufw limit in $SSH_PORT/tcp comment 'allow SSH connections on port $SSH_PORT'

UFW_DNS true ufw allow out 53 comment 'allow DNS calls out'

UFW_NTP true ufw allow out 123 comment 'allow NTP out'

UFW_HTTP false ufw allow out http comment 'allow HTTP traffic out'

UFW_HTTPS false ufw allow out https comment 'allow HTTPS traffic out'

UFW_FTP false ufw allow out ftp comment 'allow FTP traffic out'

