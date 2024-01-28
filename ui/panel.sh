#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'pterodactyl-installer'                                                    #
#                                                                                    #
# Copyright (C) 2018 - 2024, Vilhelm Prytz, <vilhelm@prytznet.se>                    #
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

# ------------ User input functions ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt requires port 80/443 to be opened! You have opted out of the automatic firewall configuration; use this at your own risk (if port 80/443 is closed, the script will fail)!"
  fi

  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=false
  fi
}

ask_assume_ssl() {
  output "Let's Encrypt is not going to be automatically configured by this script (user opted out)."
  output "You can 'assume' Let's Encrypt, which means the script will download a nginx configuration that is configured to use a Let's Encrypt certificate but the script won't obtain the certificate for you."
  output "If you assume SSL and do not obtain the certificate, your installation will not work."
  echo -n "* Assume SSL or not? (y/N): "
  read -r ASSUME_SSL_INPUT

  [[ "$ASSUME_SSL_INPUT" =~ [Yy] ]] && ASSUME_SSL=true
  true
}

check_FQDN_SSL() {
  if [[ $(invalid_ip "$FQDN") == 1 && $FQDN != 'localhost' ]]; then
    SSL_AVAILABLE=true
  else
    warning "* Let's Encrypt will not be available for IP addresses."
    output "To use Let's Encrypt, you must use a valid domain name."
  fi
}

main() {
  # check if we can detect an already existing installation
  if [ -d "/var/www/pterodactyl" ]; then
    warning "The script has detected that you already have Pterodactyl panel on your system! You cannot run the script multiple times, it will fail!"
    echo -e -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      error "Installation aborted!"
      exit 1
    fi
  fi

  welcome "panel"

  check_os_x86_64

  # set database credentials
  output "Database configuration."
  output ""
  output "This will be the credentials used for communication between the MySQL"
  output "database and the panel. You do not need to create the database"
  output "before running this script, the script will do that for you."
  output ""

  MYSQL_DB="-"
  while [[ "$MYSQL_DB" == *"-"* ]]; do
    required_input MYSQL_DB "Database name (panel): " "" "panel"
    [[ "$MYSQL_DB" == *"-"* ]] && error "Database name cannot contain hyphens"
  done

  MYSQL_USER="-"
  while [[ "$MYSQL_USER" == *"-"* ]]; do
    required_input MYSQL_USER "Database username (pterodactyl): " "" "pterodactyl"
    [[ "$MYSQL_USER" == *"-"* ]] && error "Database user cannot contain hyphens"
  done

  # MySQL password input
  rand_pw=$(gen_passwd 64)
  password_input MYSQL_PASSWORD "Password (press enter to use randomly generated password): " "MySQL password cannot be empty" "$rand_pw"

  readarray -t valid_timezones <<<"$(curl -s "$GITHUB_URL"/configs/valid_timezones.txt)"
  output "List of valid timezones here $(hyperlink "https://www.php.net/manual/en/timezones.php")"

  while [ -z "$timezone" ]; do
    echo -n "* Select timezone [Europe/Stockholm]: "
    read -r timezone_input

    array_contains_element "$timezone_input" "${valid_timezones[@]}" && timezone="$timezone_input"
    [ -z "$timezone_input" ] && timezone="Europe/Stockholm" # because köttbullar!
  done

  email_input email "Provide the email address that will be used to configure Let's Encrypt and Pterodactyl: " "Email cannot be empty or invalid"

  # Initial admin account
  email_input user_email "Email address for the initial admin account: " "Email cannot be empty or invalid"
  required_input user_username "Username for the initial admin account: " "Username cannot be empty"
  required_input user_firstname "First name for the initial admin account: " "Name cannot be empty"
  required_input user_lastname "Last name for the initial admin account: " "Name cannot be empty"
  password_input user_password "Password for the initial admin account: " "Password cannot be empty"

  print_brake 72

  # set FQDN
  while [ -z "$FQDN" ]; do
    echo -n "* Set the FQDN of this panel (panel.example.com): "
    read -r FQDN
    [ -z "$FQDN" ] && error "FQDN cannot be empty"
  done

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
  [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ] && bash <(curl -s "$GITHUB_URL"/lib/verify-fqdn.sh) "$FQDN"

  # summary
  summary

  # confirm installation
  echo -e -n "\n* Initial configuration completed. Continue with installation? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    run_installer "panel"
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
  print_brake 62
}

goodbye() {
  print_brake 62
  output "Panel installation completed"
  output ""

  [ "$CONFIGURE_LETSENCRYPT" == true ] && output "Your panel should be accessible from $(hyperlink "$FQDN")"
  [ "$ASSUME_SSL" == true ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "You have opted in to use SSL, but not via Let's Encrypt automatically. Your panel will not work until SSL has been configured."
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
