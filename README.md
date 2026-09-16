# Bastioning Script

Script de automatización para reforzar la seguridad de un servidor Linux basado en Debian/Ubuntu y convertirlo en un nodo bastión seguro.

Incluye configuración de:
- SSH hardening con autenticación por clave pública y Google Authenticator.
- Firewall UFW con reglas entrantes y salientes.
- Fail2Ban con protección por jaulas y soporte opcional para AbuseIPDB.
- Actualizaciones automáticas con unattended-upgrades.
- DDNS dinámico en Cloudflare.

## Objetivo

Este proyecto está pensado para dejar un servidor listo para exposición limitada, con políticas restrictivas de acceso y monitorización automática de intentos de acceso no autorizados.

## Requisitos

- Sistema operativo: Debian o Ubuntu.
- Usuario root o sudo suficiente para ejecutar el instalador.
- `apt-get` disponible.
- Acceso a internet para instalar paquetes y, si se usa, para Cloudflare o AbuseIPDB.

## Estructura del proyecto

```text
.
├── config.conf
├── install.sh
├── lib/
│   └── utils.sh
├── modules/
│   ├── ddns.sh
│   ├── fail2ban.sh
│   ├── ssh.sh
│   ├── ufw.sh
│   └── unattended-upgrades.sh
├── resources/
│   └── abuseipdb-check-report.sh
└── README.md
```

## Instalación

**Importante**: antes de ejecutar el instalador, debes ajustar la configuración del archivo `config.conf` con los valores correctos de tu entorno. Si no lo haces, el script puede fallar o dejar el servidor en una configuración incorrecta.

1. Ajusta la configuración en `config.conf`.
2. Verifica que el usuario indicado en `SSH_USERNAME` exista y que la clave pública de acceso esté correcta.
3. Ejecuta el instalador como root:

```bash
sudo bash install.sh
```

> El script validará que el sistema sea compatible y que los valores mínimos de configuración estén definidos antes de continuar.

## Configuración

El archivo principal de configuración es `config.conf`.

### Módulos habilitados

Cada uno de estos valores puede activarse o desactivarse según el uso del servidor.

```bash
ENABLE_DDNS="true"
ENABLE_SSH="true"
ENABLE_UFW="true"
ENABLE_FAIL2BAN="true"
ENABLE_UNATTENDED="true"
```

### Variables principales

#### SSH

```bash
SSH_USERNAME="usuario_bastion"
SSH_PORT="2222"
SSH_PUBLICKEY="ssh-ed25519 AAAA... usuario@maquina"
```

Estas opciones permiten:
- crear un usuario dedicado para acceso remoto,
- cambiar el puerto por defecto de SSH,
- bloquear el acceso root,
- desactivar autenticación por contraseña,
- activar Google Authenticator como segundo factor.

#### DDNS Cloudflare

```bash
DDNS_APIKEY=""
DDNS_ZONE_ID=""
DDNS_DOMAIN="mi-dominio.example.com"
DDNS_CRON="*/5 * * * *"
```

El módulo `ddns.sh` genera un script que actualiza el registro DNS A del dominio con la IP pública actual usando la API de Cloudflare.

#### UFW

El módulo `ufw.sh` configura el firewall con reglas de entrada y salida. El comportamiento por defecto es mínimo y exigente:

- deny incoming por defecto,
- deny outgoing por defecto,
- apertura selectiva de puertos necesarios,
- soporte para SSH, DNS, NTP, HTTP, HTTPS, SMTP y DHCP.

#### Fail2Ban

```bash
F2B_ABUSEIPDB="true"
F2B_APIKEY=""
F2B_WHITELIST=""
F2B_SSHD="true"
```

Este módulo crea la configuración local de Fail2Ban y puede:
- bloquear accesos repetidos a SSH,
- integrar reglas de protección para servicios web y otros servicios,
- añadir soporte para AbuseIPDB para reportar IPs sospechosas y bloquearlas con mayor duración,
- personalizar tiempos de baneo, búsqueda y reincidencia.

#### Unattended upgrades

```bash
UNATT_ENABLE="1"
UNATT_UPDATEDAYS="1"
UNATT_DOWNLOADDAYS="1"
UNATT_AUTOCLEAN="7"
UNATT_AUTOUPGRADE="1"
UNATT_REBOOT="true"
```

Ajusta la política de actualizaciones automáticas del sistema y activa el parcheo de seguridad sin intervención manual.

## Funcionamiento por módulos

### 1. SSH

El módulo `modules/ssh.sh`:
- instala `openssh-server` y `libpam-google-authenticator`,
- valida la existencia del usuario configurado,
- genera la configuración de Google Authenticator para ese usuario,
- instala la clave pública en `~/.ssh/authorized_keys`,
- modifica `/etc/ssh/sshd_config` para reforzar la seguridad,
- fuerza `publickey + 2FA` como método de acceso.

### 2. DDNS

El módulo `modules/ddns.sh`:
- crea el directorio `/opt/cloudflare-ddns`,
- guarda la API key en un archivo protegido,
- genera un script de actualización de DNS,
- añade la tarea de cron para ejecutarlo periódicamente.

### 3. UFW

El módulo `modules/ufw.sh`:
- instalará `ufw`,
- define políticas por defecto,
- crea reglas específicas para el tráfico permitido,
- habilita el firewall al finalizar.

### 4. Fail2Ban

El módulo `modules/fail2ban.sh`:
- instala `fail2ban` y `rsyslog`,
- genera `/etc/fail2ban/jail.local`,
- personaliza límites y tiempos de baneo,
- añade jaulas para SSH y otros servicios opcionales,
- soporta AbuseIPDB para reportes externos.

### 5. Unattended-upgrades

El módulo `modules/unattended-upgrades.sh`:
- installa `unattended-upgrades` y `apt-listchanges`,
- fuerza repositorios HTTPS si es necesario,
- genera `/etc/apt/apt.conf.d/51myunattended-upgrades`,
- ejecuta una validación de configuración con `unattended-upgrade -d --dry-run`.

## Seguridad recomendada

Antes de usar este proyecto en producción:

- cambia por defecto todos los valores sensibles en `config.conf`,
- usa únicamente claves SSH seguras,
- configura una IP o rango permitido en el firewall si tu infraestructura lo requiere,
- prueba la configuración en un entorno de staging antes de desplegarla en un servidor real,
- guarda una copia de seguridad de los archivos modificados.

## Limitaciones

- Este proyecto está orientado a Debian/Ubuntu.
- La gestión de acceso por 2FA se asume con Google Authenticator para SSH.
- Algunos servicios y puertos se habilitan solo si se configuraron explícitamente en `config.conf`.

## Licencia

Este proyecto se distribuye tal cual. Revisa la licencia del repositorio si se añade más adelante.

## Autor

Aimar Mendibil Ayo
