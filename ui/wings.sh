#!/bin/bash

set -e -o pipefail

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

# Install mariadb
export INSTALL_MARIADB=false

# Firewall
export CONFIGURE_FIREWALL=false

# SSL (Let's Encrypt)
export CONFIGURE_LETSENCRYPT=false
export FQDN=""
export EMAIL=""

# Database host
export CONFIGURE_DBHOST=false
export CONFIGURE_DB_FIREWALL=false
export MYSQL_DBHOST_HOST="127.0.0.1"
export MYSQL_DBHOST_USER="pterodactyluser"
export MYSQL_DBHOST_PASSWORD=""

# Read previous choices, made during panel installation, if exists
if [ -n "${INSTALL_SETTINGS:-}" ]; then
  if ! load_install_settings; then
    error "Invalid INSTALL_SETTINGS file."
    exit 1
  fi
fi

# ------------ User input functions ------------ #

ask_database_user() {
  echo -n "* Do you want to automatically configure a user for database hosts? (y/N): "
  read -r CONFIRM_DBHOST

  if is_yes "$CONFIRM_DBHOST"; then
    ask_database_external
    CONFIGURE_DBHOST=true
  fi
}

ask_database_external() {
  echo -n "* Do you want to configure MySQL to be accessed externally? (y/N): "
  read -r CONFIRM_DBEXTERNAL

  if is_yes "$CONFIRM_DBEXTERNAL"; then
    while true; do
      echo -n "* Enter the panel address (blank for any address): "
      read -r CONFIRM_DBEXTERNAL_HOST
      [ -z "$CONFIRM_DBEXTERNAL_HOST" ] && break
      valid_hostname "$CONFIRM_DBEXTERNAL_HOST" && break
    done
    if [ "$CONFIRM_DBEXTERNAL_HOST" == "" ]; then
      MYSQL_DBHOST_HOST="%"
    else
      MYSQL_DBHOST_HOST="${CONFIRM_DBEXTERNAL_HOST#[}"
      MYSQL_DBHOST_HOST="${MYSQL_DBHOST_HOST%]}"
    fi
    [ "$CONFIGURE_FIREWALL" == true ] && ask_database_firewall
    return 0
  fi
}

ask_database_firewall() {
  warning "Allow incoming traffic to port 3306 (MySQL) can potentially be a security risk, unless you know what you are doing!"
  echo -n "* Would you like to allow incoming traffic to port 3306? (y/N): "
  read -r CONFIRM_DB_FIREWALL
  if is_yes "$CONFIRM_DB_FIREWALL"; then
    CONFIGURE_DB_FIREWALL=true
  fi
}

####################
## MAIN FUNCTIONS ##
####################

main() {
  # check if we can detect an already existing installation
  if [ -d "/etc/pterodactyl" ]; then
    warning "The script has detected that you already have Pterodactyl wings on your system! You cannot run the script multiple times, it will fail!"
    echo -e -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if ! is_yes "$CONFIRM_PROCEED"; then
      error "Installation aborted!"
      exit 1
    fi
  fi

  welcome "wings"

  check_virt

  echo "* "
  echo "* The installer will install Docker, required dependencies for Wings"
  echo "* as well as Wings itself. But it's still required to create the node"
  echo "* on the panel and then place the configuration file on the node manually after"
  echo "* the installation has finished. Read more about this process on the"
  echo "* official documentation: $(hyperlink "https://docs.pterodactyl.io/v${PANEL_MAJOR_VERSION:-1}/wings/installing#configuring-wings")"
  echo "* "
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not start Wings automatically (will install systemd service, not start it)."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not enable swap (for docker)."
  print_brake 42

  [ -s "${INSTALL_SETTINGS:-}" ] || ask_firewall CONFIGURE_FIREWALL

  ask_database_user

  if [ "$CONFIGURE_DBHOST" == true ]; then
    { type -P mariadb >/dev/null 2>&1 || type -P mysql >/dev/null 2>&1; } && HAS_MYSQL=true || HAS_MYSQL=false

    if [ "$HAS_MYSQL" == false ]; then
      INSTALL_MARIADB=true
    fi

    while true; do
      required_input MYSQL_DBHOST_USER "Database host username (pterodactyluser): " "" "pterodactyluser"
      valid_database_identifier "$MYSQL_DBHOST_USER" && break
    done

    password_input MYSQL_DBHOST_PASSWORD "Database host password: " "Password cannot be empty"
  fi

  if [ ! -s "${INSTALL_SETTINGS:-}" ]; then
    warning "You cannot use Let's Encrypt with your hostname as an IP address! It must be a FQDN (e.g. node.example.org)."
    ask_letsencrypt
  fi

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while [ "$CONFIGURE_LETSENCRYPT" == true ] && [ -z "$FQDN" ]; do
      echo -n "* Set the FQDN to use for Let's Encrypt (node.example.com): "
      read -r FQDN

      ASK=false

      [ -z "$FQDN" ] && error "FQDN cannot be empty" && continue
      if ! valid_hostname "$FQDN"; then
        FQDN=""
        continue
      fi
      if is_ip_address "$FQDN" || [ "$FQDN" == localhost ]; then
        error "Let's Encrypt requires a public hostname, not an IP address or localhost."
        FQDN=""
        continue
      fi
      FQDN="${FQDN%.}"
      verify_fqdn "$FQDN" || ASK=true

      [ "$ASK" == true ] && FQDN=""
      [ "$ASK" == true ] && echo -e -n "* Do you still want to automatically configure HTTPS using Let's Encrypt? (y/N): "
      [ "$ASK" == true ] && read -r CONFIRM_SSL

      if ! is_yes "$CONFIRM_SSL" && [ "$ASK" == true ]; then
        CONFIGURE_LETSENCRYPT=false
        FQDN=""
      fi
    done
  fi

  if [ "$CONFIGURE_LETSENCRYPT" == true ] && ! valid_email "$EMAIL"; then
    email_input EMAIL "Enter email address for Let's Encrypt: " "Email cannot be empty or invalid"
  fi

  echo -n "* Proceed with installation? (y/N): "

  read -r CONFIRM
  if is_yes "$CONFIRM"; then
    run_installer "wings"
  else
    error "Installation aborted."
    exit 1
  fi
}

function goodbye {
  echo ""
  print_brake 70
  echo "* Wings installation completed"
  echo "*"
  echo "* To continue, you need to configure Wings to run with your panel"
  echo "* Please refer to the official guide, $(hyperlink "https://docs.pterodactyl.io/v${PANEL_MAJOR_VERSION:-1}/wings/installing#configuring-wings")"
  echo "* "
  echo "* You can either copy the configuration file from the panel manually to /etc/pterodactyl/config.yml"
  echo "* or, you can use the \"auto deploy\" button from the panel and simply paste the command in this terminal"
  echo "* "
  echo "* You can then start Wings manually to verify that it's working"
  echo "*"
  echo "* sudo wings"
  echo "*"
  echo "* Once you have verified that it is working, use CTRL+C and then start Wings as a service (runs in the background)"
  echo "*"
  echo "* systemctl start wings"
  echo "*"
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: It is recommended to enable swap (for Docker, read more about it in official documentation)."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured your firewall, ports 8080 and 2022 needs to be open."
  print_brake 70
  echo ""
}

# run script
main
goodbye
