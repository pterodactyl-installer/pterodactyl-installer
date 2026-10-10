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

# Domain name / IP
export FQDN=""

# Default MySQL credentials
export MYSQL_DB=""
export MYSQL_USER=""
export MYSQL_PASSWORD=""

# Environment
export timezone=""
export email=""
export telemetry=""

# Initial admin account
export user_email=""
export user_username=""
export user_firstname=""
export user_lastname=""
export user_password=""

# Assume SSL, will fetch different config if true
export ASSUME_SSL=false
export CONFIGURE_LETSENCRYPT=false

# Firewall
export CONFIGURE_FIREWALL=false

if [ -z "${INSTALL_SETTINGS:-}" ]; then
  INSTALL_SETTINGS=$(mktemp)
  export INSTALL_SETTINGS
  trap 'rm -f "$INSTALL_SETTINGS"' EXIT
fi
check_install_settings

# ------------ User input functions ------------ #

ask_assume_ssl() {
  output "Let's Encrypt is not going to be automatically configured by this script (user opted out)."
  output "You can assume SSL to use an nginx HTTPS configuration with your own certificate."
  output "Place your certificate at /etc/ssl/$FQDN.pem and its private key at /etc/ssl/$FQDN.key before starting nginx."
  output "After installation, run nginx -t && systemctl restart nginx once both certificate files are in place."
  echo -n "* Assume SSL or not? (y/N): "
  read -r ASSUME_SSL_INPUT

  is_yes "$ASSUME_SSL_INPUT" && ASSUME_SSL=true
  true
}

ask_telemetry() {
  output "Pterodactyl Panel collects anonymous telemetry data to help steer the development."
  output "More Info: https://docs.pterodactyl.io/v$PANEL_MAJOR_VERSION/panel/additional-configuration#telemetry"
  echo -n "* Enable sending anonymous telemetry data? (yes/no) [yes]: "
  read -r telemetry_input

  if [[ -z "$telemetry_input" ]] || is_yes "$telemetry_input"; then
    telemetry="true"
  else
    telemetry="false"
  fi
}

check_FQDN_SSL() {
  SSL_AVAILABLE=false
  if ! is_ip_address "$FQDN" && [ "$FQDN" != localhost ]; then
    SSL_AVAILABLE=true
  else
    warning "* Let's Encrypt will not be available for IP addresses."
    output "To use Let's Encrypt, you must use a valid domain name."
  fi
}

main() {
  # check if we can detect an already existing installation
  if [ -d "/var/www/pterodactyl" ]; then
    error "An existing Panel installation was detected. This script only supports fresh installations."
    output "You can remove existing installations by running the uninstall script."
    output "You can upgrade your existing installation using the following guide: https://docs.pterodactyl.io/v2/upgrading/upgrading-from-v1"
    exit 1
  fi

  ask_panel_version
  welcome "panel"

  check_os_x86_64

  # set database credentials
  output "Database configuration."
  output ""
  output "This will be the credentials used for communication between the MySQL"
  output "database and the panel. You do not need to create the database"
  output "before running this script, the script will do that for you."
  output ""

  while true; do
    required_input MYSQL_DB "Database name (panel): " "" "panel"
    valid_database_identifier "$MYSQL_DB" && break
  done

  while true; do
    required_input MYSQL_USER "Database username (pterodactyl): " "" "pterodactyl"
    valid_database_identifier "$MYSQL_USER" && break
  done

  # MySQL password input
  rand_pw=$(gen_passwd 64)
  while true; do
    password_input MYSQL_PASSWORD "Password (press enter to use randomly generated password): " "MySQL password cannot be empty" "$rand_pw"
    valid_panel_database_password "$MYSQL_PASSWORD" && break
  done

  timezone_list=$(curl -fsSL "$GITHUB_URL/configs/valid_timezones.txt")
  readarray -t valid_timezones <<<"$timezone_list"
  output "List of valid timezones here $(hyperlink "https://www.php.net/manual/en/timezones.php")"

  while [ -z "$timezone" ]; do
    echo -n "* Select timezone [Europe/Stockholm]: "
    read -r timezone_input

    array_contains_element "$timezone_input" "${valid_timezones[@]}" && timezone="$timezone_input"
    [ -z "$timezone_input" ] && timezone="Europe/Stockholm" # because köttbullar!
    [ -n "$timezone" ] || error "Invalid timezone. Try again."
  done

  email_input email "Provide the email address that will be used to configure Let's Encrypt and Pterodactyl: " "Email cannot be empty or invalid"

  # Initial admin account
  email_input user_email "Email address for the initial admin account [$email]: " "Email cannot be empty or invalid" "$email"
  while true; do
    required_input user_username "Username for the initial admin account: " "Username cannot be empty"
    valid_admin_username "$user_username" && break
  done
  while true; do
    required_input user_firstname "First name for the initial admin account: " "Name cannot be empty"
    valid_admin_name "$user_firstname" && break
  done
  while true; do
    required_input user_lastname "Last name for the initial admin account: " "Name cannot be empty"
    valid_admin_name "$user_lastname" && break
  done
  while true; do
    password_input user_password "Password for the initial admin account: " "Password cannot be empty"
    valid_admin_password "$user_password" && break
  done

  print_brake 72

  # set FQDN
  while true; do
    echo -n "* Set the FQDN of this panel (panel.example.com): "
    read -r FQDN
    valid_hostname "$FQDN" && break
  done
  FQDN="${FQDN%.}"
  [[ "$FQDN" != *:* || "$FQDN" == '['*']' ]] || FQDN="[$FQDN]"

  # Check if SSL is available
  check_FQDN_SSL

  # Ask if firewall is needed
  ask_firewall CONFIGURE_FIREWALL

  # Only ask about SSL if it is available
  if [ "$SSL_AVAILABLE" == true ]; then
    # Ask if letsencrypt is needed
    ask_letsencrypt
    # If it's already true, this should be a no-brainer
    [ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl
  fi

  # verify FQDN if user has selected to assume SSL or configure Let's Encrypt
  if [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ]; then
    verify_fqdn "$FQDN"
  fi

  # ask telemetry preference
  ask_telemetry

  # summary
  summary

  # confirm installation
  echo -e -n "\n* Initial configuration completed. Continue with installation? (y/N): "
  read -r CONFIRM
  if is_yes "$CONFIRM"; then
    run_installer "panel"
    load_install_settings
  else
    error "Installation aborted."
    exit 1
  fi
}

summary() {
  print_brake 62
  output "Pterodactyl panel $PTERODACTYL_PANEL_VERSION with nginx on $OS"
  output "Database name: $MYSQL_DB"
  output "Database user: $MYSQL_USER"
  output "Database password: (censored)"
  output "Timezone: $timezone"
  output "Email: $email"
  output "User email: $user_email"
  output "Username: $user_username"
  output "First name: $user_firstname"
  output "Last name: $user_lastname"
  output "User password: (censored)"
  output "Hostname/FQDN: $FQDN"
  output "Configure Firewall? $CONFIGURE_FIREWALL"
  output "Configure Let's Encrypt? $CONFIGURE_LETSENCRYPT"
  output "Assume SSL? $ASSUME_SSL"
  output "Telemetry: $telemetry"
  print_brake 62
}

goodbye() {
  print_brake 62
  output "Panel installation completed"
  output ""

  [ "$CONFIGURE_LETSENCRYPT" == true ] && output "Your panel should be accessible from $(hyperlink "$FQDN")"
  if [ "$ASSUME_SSL" == true ] && [ "$CONFIGURE_LETSENCRYPT" == false ]; then
    output "You have opted in to use SSL, but not via Let's Encrypt automatically. Your panel will not work until SSL has been configured."
    output "Place your certificate at /etc/ssl/$FQDN.pem and its private key at /etc/ssl/$FQDN.key, then run nginx -t && systemctl restart nginx."
  fi
  [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Your panel should be accessible from $(hyperlink "$FQDN")"

  output ""
  output "Installation is using nginx on $OS"
  output "Thank you for using this script."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured the firewall: 80/443 (HTTP/HTTPS) is required to be open!"
  print_brake 62
}

# run script
main
goodbye
