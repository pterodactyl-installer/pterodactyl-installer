#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'pterodactyl-installer'                                                    #
#                                                                                    #
# Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>                    #
#                                                                                    #
#   This program is free software: you can redistribute it and/or modify             #
#   it under the terms of the GNU General Public License as published by             #
#   the Free Software Foundation, either version 3 of the License, or                #
#   (at your option) any later version.                                              #
#                                                                                    #
#   This program is distributed in the hope that it will be useful,                  #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of                   #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                    #
#   GNU General Public License for more details.                                     #
#                                                                                    #
#   You should have received a copy of the GNU General Public License                #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.           #
#                                                                                    #
# https://github.com/pterodactyl-installer/pterodactyl-installer/blob/master/LICENSE #
#                                                                                    #
# This script is not associated with the official Pterodactyl Project.               #
# https://github.com/pterodactyl-installer/pterodactyl-installer                     #
#                                                                                    #
######################################################################################

# Check if script is loaded, load if not or fail otherwise.
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  # shellcheck source=lib/lib.sh
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERROR: Could not load lib script" && exit 1
fi

# ------------------ Variables ----------------- #

INSTALL_MARIADB="${INSTALL_MARIADB:-false}"

# firewall
CONFIGURE_FIREWALL="${CONFIGURE_FIREWALL:-false}"

# Game server ports
CONFIGURE_GAMESERVER_PORTS="${CONFIGURE_GAMESERVER_PORTS:-false}"

# SSL (Let's Encrypt)
CONFIGURE_LETSENCRYPT="${CONFIGURE_LETSENCRYPT:-false}"
FQDN="${FQDN:-}"
EMAIL="${EMAIL:-}"

# Database host
CONFIGURE_DBHOST="${CONFIGURE_DBHOST:-false}"
CONFIGURE_DB_FIREWALL="${CONFIGURE_DB_FIREWALL:-false}"
MYSQL_DBHOST_HOST="${MYSQL_DBHOST_HOST:-127.0.0.1}"
MYSQL_DBHOST_USER="${MYSQL_DBHOST_USER:-pterodactyluser}"
MYSQL_DBHOST_PASSWORD="${MYSQL_DBHOST_PASSWORD:-}"

# Auto node configuration
CONFIGURE_NODE="${CONFIGURE_NODE:-false}"
PANEL_URL="${PANEL_URL:-}"
NODE_TOKEN="${NODE_TOKEN:-}"
ALLOW_INSECURE="${ALLOW_INSECURE:-false}"

if [[ $CONFIGURE_DBHOST == true && -z "${MYSQL_DBHOST_PASSWORD}" ]]; then
  error "Mysql database host user password is required"
  exit 1
fi

if [[ $CONFIGURE_NODE == true && ( -z "${PANEL_URL}" || -z "${NODE_TOKEN}" ) ]]; then
  error "Panel URL and node token are required for auto node configuration"
  exit 1
fi

# ----------- Installation functions ----------- #

enable_services() {
  [ "$INSTALL_MARIADB" == true ] && systemctl enable mariadb
  [ "$INSTALL_MARIADB" == true ] && systemctl start mariadb
  systemctl start docker
  systemctl enable docker
}

dep_install() {
  output "Installing dependencies for $OS $OS_VER..."

  [ "$CONFIGURE_FIREWALL" == true ] && install_firewall && firewall_ports

  # Check if Docker is already installed
  if command -v docker &>/dev/null; then
    output "Docker is already installed, skipping repository setup. Packages will still be verified..."
  else
    # Docker not installed, set up repositories
    case "$OS" in
    ubuntu | debian)
      install_packages "ca-certificates gnupg lsb-release"

      mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
      ;;

    rocky | almalinux)
      install_packages "dnf-utils"
      dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

      install_packages "device-mapper-persistent-data lvm2"
      ;;
    esac

    # Update the new repos
    update_repos
  fi

  # Install Docker packages - ensures all components are present
  # For existing Docker: installs any missing packages (e.g., containerd.io)
  # For fresh install: installs all Docker packages after repo setup
  install_packages "docker-ce docker-ce-cli containerd.io"

  # Install epel-release for certbot on rocky/almalinux (needed regardless of Docker status)
  case "$OS" in
  rocky | almalinux)
    [ "$CONFIGURE_LETSENCRYPT" == true ] && install_packages "epel-release"
    ;;
  esac

  # Install mariadb if needed
  [ "$INSTALL_MARIADB" == true ] && install_packages "mariadb-server"
  [ "$CONFIGURE_LETSENCRYPT" == true ] && install_packages "certbot"

  enable_services

  success "Dependencies installed!"
}

ptdl_dl() {
  echo "* Downloading Pterodactyl Wings.. "

  mkdir -p /etc/pterodactyl
  curl -L -o /usr/local/bin/wings "$WINGS_DL_BASE_URL$ARCH"

  chmod u+x /usr/local/bin/wings

  success "Pterodactyl Wings downloaded successfully"
}

systemd_file() {
  output "Installing systemd service.."

  curl -o /etc/systemd/system/wings.service "$GITHUB_URL"/configs/wings.service
  systemctl daemon-reload
  systemctl enable wings

  success "Installed systemd service!"
}

firewall_ports() {
  output "Opening port 22 (SSH), 8080 (Wings Port), 2022 (Wings SFTP Port)"

  [ "$CONFIGURE_LETSENCRYPT" == true ] && firewall_allow_ports "80 443"
  [ "$CONFIGURE_DB_FIREWALL" == true ] && firewall_allow_ports "3306"

  firewall_allow_ports "22"
  output "Allowed port 22"
  firewall_allow_ports "8080"
  output "Allowed port 8080"
  firewall_allow_ports "2022"
  output "Allowed port 2022"

  if [ "$CONFIGURE_GAMESERVER_PORTS" == true ]; then
    output "Opening game server ports (19132/UDP, 25500-25600/TCP+UDP)..."

    # Use OS-appropriate port range syntax for firewall backends:
    # - UFW (Debian/Ubuntu) expects colon syntax (25500:25600)
    # - firewall-cmd (Rocky/AlmaLinux) expects hyphen syntax (25500-25600)
    GAME_PORT_RANGE="25500:25600"
    case "$OS" in
    rocky | almalinux)
      GAME_PORT_RANGE="25500-25600"
      ;;
    esac

    firewall_allow_ports_udp "19132"
    output "Allowed port 19132/UDP (Minecraft Bedrock)"
    firewall_allow_ports "$GAME_PORT_RANGE"
    output "Allowed ports 25500-25600/TCP"
    firewall_allow_ports_udp "$GAME_PORT_RANGE"
    output "Allowed ports 25500-25600/UDP"
  fi

  success "Firewall ports opened!"
}

letsencrypt() {
  FAILED=false

  output "Configuring LetsEncrypt.."

  # If user has nginx
  systemctl stop nginx || true

  # Obtain certificate
  certbot certonly --no-eff-email --email "$EMAIL" --standalone -d "$FQDN" || FAILED=true

  systemctl start nginx || true

  # Check if it succeded
  if [ ! -d "/etc/letsencrypt/live/$FQDN/" ] || [ "$FAILED" == true ]; then
    warning "The process of obtaining a Let's Encrypt certificate failed!"
  else
    success "The process of obtaining a Let's Encrypt certificate succeeded!"
  fi
}

configure_mysql() {
  output "Configuring MySQL.."

  create_db_user "$MYSQL_DBHOST_USER" "$MYSQL_DBHOST_PASSWORD" "$MYSQL_DBHOST_HOST"
  grant_all_privileges "*" "$MYSQL_DBHOST_USER" "$MYSQL_DBHOST_HOST"

  if [ "$MYSQL_DBHOST_HOST" != "127.0.0.1" ]; then
    echo "* Changing MySQL bind address.."

    case "$OS" in
    debian | ubuntu)
      sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf
      ;;
    rocky | almalinux)
      sed -ne 's/^#bind-address=0.0.0.0$/bind-address=0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf
      ;;
    esac

    systemctl restart mysqld
  fi

  success "MySQL configured!"
}

configure_node() {
  output "Configuring node with panel.."

  if [ ! -d "/etc/pterodactyl" ]; then
    error "Directory /etc/pterodactyl does not exist. Wings may not have been downloaded correctly."
    exit 1
  fi

  # Verify wings binary exists and is executable
  if [ ! -x "/usr/local/bin/wings" ]; then
    error "Wings binary not found or not executable at /usr/local/bin/wings"
    exit 1
  fi

  cd /etc/pterodactyl || exit

  # Build the wings configure command using an array (safe from command injection)
  WINGS_ARGS=("configure" "--panel-url" "$PANEL_URL" "--token" "$NODE_TOKEN")
  
  # Add --allow-insecure flag if needed (for self-signed certs or SSL issues)
  if [ "$ALLOW_INSECURE" == true ]; then
    WINGS_ARGS+=("--allow-insecure")
    warning "Running with --allow-insecure flag (SSL certificate verification disabled)"
  fi

  # Build a human-readable command string for logging
  local WINGS_CMD_DISPLAY="wings configure --panel-url [PANEL_URL] --token [HIDDEN]"
  if [ "$ALLOW_INSECURE" == true ]; then
    WINGS_CMD_DISPLAY+=" --allow-insecure"
  fi
  output "Running: $WINGS_CMD_DISPLAY"

  # Execute the command using array expansion (safe execution) and capture output
  local WINGS_OUTPUT
  local WINGS_EXIT_CODE
  WINGS_OUTPUT=$(wings "${WINGS_ARGS[@]}" 2>&1)
  WINGS_EXIT_CODE=$?

  if [ $WINGS_EXIT_CODE -eq 0 ]; then
    success "Node configured successfully!"
    
    # Verify config file was created
    if [ -f "/etc/pterodactyl/config.yml" ]; then
      output "Configuration file created at /etc/pterodactyl/config.yml"
    else
      warning "Configuration command succeeded but config.yml was not found"
    fi
  else
    error "Failed to configure node with panel (exit code: $WINGS_EXIT_CODE)"
    if [ -n "$WINGS_OUTPUT" ]; then
      error "Wings output:"
      echo "$WINGS_OUTPUT" | while IFS= read -r line; do
        error "  $line"
      done
    fi
    error ""
    error "Please check:"
    error "  - Panel URL is correct and reachable"
    error "  - Token is valid and not expired"
    error "  - Panel is running and accessible"
    if [ "$ALLOW_INSECURE" != true ]; then
      error "  - If using self-signed certificates, try with --allow-insecure option"
    fi
    exit 1
  fi
}

# --------------- Main functions --------------- #

perform_install() {
  output "Installing pterodactyl wings.."
  dep_install
  ptdl_dl
  systemd_file
  [ "$CONFIGURE_DBHOST" == true ] && configure_mysql
  [ "$CONFIGURE_LETSENCRYPT" == true ] && letsencrypt
  [ "$CONFIGURE_NODE" == true ] && configure_node

  return 0
}

# ---------------- Installation ---------------- #

perform_install
