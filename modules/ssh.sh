#!/bin/bash

#################################################
#  Script de instalacion de sshd junto con mfa  #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################

install_package ssh
install_package libpam-google-authentificator

backup_file /etc/pam.d/sshd
backup_file /etc/ssh/sshd_config

service_start ssh
service_enable ssh

google-authenticator --quiet --no-prompt --force --disallow-reuse --allow-reroot
