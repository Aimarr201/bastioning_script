#!/bin/bash

#################################################
#      Script de configuracion de fail2ban      #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################

# instalar paquetes
install_package fail2ban
if ipdb true install_package curl 
             install_package python3-pip
             pip3 install abuseipdb
if LOGROTATE true install_package wget

service_start fail2ban
service_enable fail2ban

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

if ipdb true replace_or_add "/etc/fail2ban/action.d/abuseipdb.conf" "abuseipdb_apikey" "$F2B_APIKEY"
             sudo systemctl restart rsyslog

if LOGROTATE true wget -O /etc/logrotate.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/debian/debian/fail2ban.logrotate

service_restart fail2ban






# Archivo de configuración jail.local

[DEFAULT]

bantime = 3h
findtime = 10m
maxretry = 5

ignoreip = 127.0.0.1


[recidive]
enabled   = true
bantime   = 4w
findtime  = 3d
maxretry = 3


[sshd]
enabled = true