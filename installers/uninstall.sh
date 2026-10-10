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

RM_PANEL="${RM_PANEL:-true}"
RM_WINGS="${RM_WINGS:-true}"

# ---------- Uninstallation functions ---------- #

disable_service() {
  if systemctl cat "$1" >/dev/null 2>&1; then
    systemctl disable --now "$1"
  fi
}

rm_panel_files() {
  output "Removing panel files..."
  rm -rf /var/www/pterodactyl
  rm -f /var/log/nginx/pterodactyl.app-access.log* /var/log/nginx/pterodactyl.app-error.log*
  case "$OS" in
  ubuntu | debian)
    [ ! -L /etc/nginx/sites-enabled/pterodactyl.conf ] || unlink /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    [ -L /etc/nginx/sites-enabled/default ] || [ ! -f /etc/nginx/sites-available/default ] || ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    ;;
  rocky | almalinux)
    rm -f /etc/nginx/conf.d/pterodactyl.conf
    ;;
  esac
  systemctl restart nginx
  success "Removed panel files."
}

rm_docker_containers() {
  output "Removing Wings docker containers..."

  local container
  local containers
  type -P docker >/dev/null 2>&1 || return 0
  containers=$(docker ps -aq --filter label=Service=Pterodactyl)
  for container in $containers; do
    docker rm -fv "$container"
  done

  success "Removed Wings docker containers. Shared images and named volumes are retained."
}

rm_wings_files() {
  output "Removing wings files..."

  [ -f /etc/systemd/system/wings.service ] && rm -rf /etc/systemd/system/wings.service

  [ -d /etc/pterodactyl ] && rm -rf /etc/pterodactyl
  [ -f /usr/local/bin/wings ] && rm -rf /usr/local/bin/wings
  [ -d /var/lib/pterodactyl ] && rm -rf /var/lib/pterodactyl
  rm -rf /var/log/pterodactyl /run/wings /tmp/pterodactyl
  rm -f /etc/logrotate.d/wings
  systemctl daemon-reload
  success "Removed wings files."
}

rm_services() {
  output "Removing services..."
  disable_service pteroq
  rm -rf /etc/systemd/system/pteroq.service
  disable_service "$CACHE_SERVICE"
  case "$OS" in
  rocky | almalinux)
    disable_service php-fpm
    rm -rf /etc/php-fpm.d/www-pterodactyl.conf
    ;;
  esac
  systemctl daemon-reload
  success "Removed services."
}

rm_cron() {
  output "Removing cron jobs..."
  { crontab -l 2>/dev/null || true; } | {
    grep -vF "/var/www/pterodactyl/artisan schedule:run" || [ "$?" == 1 ]
  } | crontab -
  success "Removed cron jobs."
}

rm_database() {
  output "Removing database..."
  if ! check_database_connection; then
    warning "Skipping database removal."
    return 0
  fi
  valid_db=$(mariadb -u root -N -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys');")
  if [[ -z "$valid_db" ]]; then
    warning "No valid databases found."
    return
  fi

  warning "Be careful! This database will be deleted!"
  if grep -qxF panel <<<"$valid_db"; then
    echo -n "* Database called panel has been detected. Is it the pterodactyl database? (y/N): "
    read -r is_panel
    if is_yes "$is_panel"; then
      DATABASE=panel
    else
      print_list "$valid_db"
    fi
  else
    print_list "$valid_db"
  fi

  while [ -z "$DATABASE" ] || ! grep -qxF "$DATABASE" <<<"$valid_db"; do
    echo -n "* Choose the panel database (to skip don't input anything): "
    read -r database_input
    if [[ -n "$database_input" ]]; then
      if grep -qxF "$database_input" <<<"$valid_db"; then
        DATABASE="$database_input"
      else
        warning "Invalid database name. Try again."
      fi
    else
      break
    fi
  done

  if [[ -n "$DATABASE" ]]; then
    mariadb -u root -e "DROP DATABASE \`${DATABASE//\`/\`\`}\`;" 2>/dev/null || warning "Failed to drop database $DATABASE."
  else
    output "No database selected, skipping removal."
  fi

  output "Removing database user..."
  valid_users=$(mariadb -u root -N -e "SELECT user FROM mysql.user WHERE host = '127.0.0.1' AND user != 'root';")
  if [[ -z "$valid_users" ]]; then
    warning "No valid database users found."
    return
  fi

  warning "Be careful! This user will be deleted!"
  if grep -qxF pterodactyl <<<"$valid_users"; then
    echo -n "* User called pterodactyl has been detected. Is it the pterodactyl user? (y/N): "
    read -r is_user
    if is_yes "$is_user"; then
      DB_USER=pterodactyl
    else
      print_list "$valid_users"
    fi
  else
    print_list "$valid_users"
  fi

  while [ -z "$DB_USER" ] || ! grep -qxF "$DB_USER" <<<"$valid_users"; do
    echo -n "* Choose the panel user (to skip don't input anything): "
    read -r user_input
    if [[ -n "$user_input" ]]; then
      if grep -qxF "$user_input" <<<"$valid_users"; then
        DB_USER=$user_input
      else
        warning "Invalid username. Try again."
      fi
    else
      break
    fi
  done

  if [[ -n "$DB_USER" ]]; then
    valid_database_identifier "$DB_USER" || return 1
    mariadb -u root -e "DROP USER '$DB_USER'@'127.0.0.1';" 2>/dev/null || warning "Failed to drop user $DB_USER."
  else
    output "No user selected, skipping removal."
  fi

  mariadb -u root -e "FLUSH PRIVILEGES;" 2>/dev/null
  success "Removed database and database user (if selected)."
}

rm_certificates() {
  local certificate
  local confirm
  for certificate in $certificates; do
    [ -d "/etc/letsencrypt/live/$certificate" ] || continue
    if grep -rFq "/etc/letsencrypt/live/$certificate/" /etc/nginx /etc/pterodactyl 2>/dev/null; then
      output "Keeping shared certificate $certificate."
      continue
    fi
    echo -n "* Remove Let's Encrypt certificate $certificate? (y/N): "
    read -r confirm
    is_yes "$confirm" && certbot delete --non-interactive --cert-name "$certificate"
  done
  return 0
}


# --------------- Main functions --------------- #

perform_uninstall() {
  certificates=$({
    if [ "$RM_PANEL" == true ]; then
      grep -hEo '/etc/letsencrypt/live/[^/[:space:]]+/' /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/conf.d/pterodactyl.conf 2>/dev/null || true
    fi
    if [ "$RM_WINGS" == true ]; then
      grep -Eo '/etc/letsencrypt/live/[^/[:space:]]+/' /etc/pterodactyl/config.yml 2>/dev/null || true
    fi
  } | cut -d/ -f5 | sort -u)
  [ "$RM_PANEL" == true ] && rm_services
  [ "$RM_PANEL" == true ] && rm_panel_files
  [ "$RM_PANEL" == true ] && rm_cron
  [ "$RM_PANEL" == true ] && rm_database
  [ "$RM_WINGS" == true ] && disable_service wings
  [ "$RM_WINGS" == true ] && rm_docker_containers
  [ "$RM_WINGS" == true ] && rm_wings_files
  rm_certificates

  return 0
}

# ------------------ Uninstall ----------------- #

perform_uninstall
