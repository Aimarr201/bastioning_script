#!/bin/bash

#################################################
#  Script de instalacion de sshd junto con mfa  #
#     Proyecto de bastionado de un servidor     #
#           Autor: Aimar Mendibil Ayo           #
#################################################

install_package ssh
install_package libpam-google-authenticator

backup_file /etc/pam.d/sshd
backup_file /etc/ssh/sshd_config

service_start ssh
service_enable ssh

sudo -u $SSH_USERNAME google-authenticator -t -C -f -q -e 5 -Q NONE -d -w 3 -r 3 -R 30

cat >> /home/$SSH_USERNAME/.ssh/authorized_keys <<EOF
$SSH_PUBLICKEY
EOF

cat > /etc/ssh/sshd_config <<EOF
Include /etc/ssh/sshd_config.d/*.conf

# Puerto SSH recomenadado cambiarlo (por defecto 22) para evitar escaneos automaticos
Port $SSH_PORT

# Desactiva el login como root directamente
PermitRootLogin no

# No permitir inicio de sesión con contraseñas (solo claves públicas + 2FA)
PasswordAuthentication no

# Activar challenge-response (necesario para 2FA con Google Authenticator)
ChallengeResponseAuthentication yes

# Permitir autenticación con clave pública
PubkeyAuthentication yes

# Usar PAM para integrar Google Authenticator (TOTP) como segundo factor
UsePAM yes

# Método de autenticación: clave pública + 2FA (keyboard-interactive)
AuthenticationMethods publickey,keyboard-interactive

# Desactivar autenticación interactiva por teclado basada en contraseña tradicional
KbdInteractiveAuthentication no

# Usar solo el protocolo 2 (el protocolo 1 es inseguro y obsoleto)
Protocol 2

# Registrar información detallada, incluyendo las claves utilizadas en los accesos
LogLevel VERBOSE

# No mostrar el mensaje de bienvenida del sistema
PrintMotd no

# No permitir login si la contraseña del usuario está vacía
PermitEmptyPasswords no

# Evitar que los usuarios puedan definir variables de entorno con .ssh/environment
PermitUserEnvironment no

# Ignorar archivos heredados de autenticación antigua (rhosts/shosts)
IgnoreRhosts yes

# Desactivar autenticación basada en hostname (insegura y poco fiable)
HostbasedAuthentication no

# Habilita la validación inversa del DNS para verificar si la IP coincide con el hostname
UseDNS yes

# Desactiva la compresión de datos para prevenir ataques como CRIME y ahorrar CPU
Compression no

# No mantener conexiones colgadas si el cliente desaparece
TCPKeepAlive no

# Evita que el servidor acceda a tu agente SSH (ssh-agent)
AllowAgentForwarding no

# Desactiva reenvío de puertos TCP desde el cliente al servidor
AllowTcpForwarding no

# Desactiva reenvío de puertos Unix locales
AllowStreamLocalForwarding no

# No permitir que los usuarios creen túneles de red vía SSH
PermitTunnel no

# Asegura que el servidor solo use algoritmos modernos y seguros para intercambio de claves
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

# Define los cifrados aceptados, priorizando los más seguros
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# Define los algoritmos de verificación de integridad de los mensajes
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com

# Define las claves del servidor por orden de preferencia (ed25519 es la más segura y rápida)
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key

# Registra actividades SFTP con más detalle
Subsystem sftp internal-sftp -f AUTHPRIV -l INFO

# Permite que el cliente pase variables de entorno específicas al servidor
AcceptEnv LANG LC_* COLORTERM NO_COLOR
EOF

cat > /etc/pam.d/sshd_config <<EOF
# Configuración PAM para el servicio Secure Shell

# Autenticación de dos factores con Google Authenticator
auth required pam_google_authenticator.so

# Autenticación estándar de Un*x.
#@include common-auth

# Deshabilitar inicios de sesión no-root cuando /etc/nologin exista.
account    required     pam_nologin.so

# Descomentar y editar /etc/security/access.conf si necesitas establecer límites complejos
# de acceso que son difíciles de expresar en sshd_config.
# account  required     pam_access.so

# Autorización estándar de Un*x.
@include common-account

# SELinux debe ser la primera regla de sesión. Esto asegura que cualquier
# contexto pendiente haya sido limpiado. Sin esto, es posible que un
# módulo ejecute código en el dominio incorrecto.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so close

# Establecer el atributo del proceso loginuid.
session    required     pam_loginuid.so

# Crear una nueva clave de sesión.
session    optional     pam_keyinit.so force revoke

# Configuración y cierre estándar de sesión en Un*x.
@include common-session

# Imprimir el mensaje del día tras un inicio de sesión exitoso.
# Esto incluye una parte generada dinámicamente desde /run/motd.dynamic
# y una parte estática (editable por el administrador) desde /etc/motd.
session    optional     pam_motd.so  motd=/run/motd.dynamic
session    optional     pam_motd.so noupdate

# Imprimir el estado del buzón de correo del usuario tras un inicio de sesión exitoso.
session    optional     pam_mail.so standard noenv # [1]

# Configurar los límites del usuario desde /etc/security/limits.conf.
session    required     pam_limits.so

# Leer las variables de entorno desde /etc/environment y
# /etc/security/pam_env.conf.
session    required     pam_env.so # [1]
# En Debian 4.0 (etch), las variables de entorno relacionadas con el locale se movieron a
# /etc/default/locale, así que también se lee ese archivo.
session    required     pam_env.so envfile=/etc/default/locale

# SELinux necesita intervenir en el momento del inicio de sesión para asegurar que el proceso
# comience en el contexto de seguridad adecuado. Solo las sesiones que están destinadas
# a ejecutarse en el contexto del usuario deben ejecutarse después de esto.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so open

# Actualización estándar de contraseñas de Un*x.
@include common-password
EOF

service_restart ssh