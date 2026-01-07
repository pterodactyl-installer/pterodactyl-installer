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

# Install mariadb
export INSTALL_MARIADB=false

# Firewall
export CONFIGURE_FIREWALL=false

# Game server ports
export CONFIGURE_GAMESERVER_PORTS=false

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

# Auto node configuration
export CONFIGURE_NODE=false
export PANEL_URL=""
export NODE_TOKEN=""
export ALLOW_INSECURE=false

# ------------ User input functions ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt requires port 80/443 to be opened! You have opted out of the automatic firewall configuration; use this at your own risk (if port 80/443 is closed, the script will fail)!"
  fi

  warning "You cannot use Let's Encrypt with your hostname as an IP address! It must be a FQDN (e.g. node.example.org)."

  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
  fi
}

ask_database_user() {
  echo -n "* Do you want to automatically configure a user for database hosts? (y/N): "
  read -r CONFIRM_DBHOST

  if [[ "$CONFIRM_DBHOST" =~ [Yy] ]]; then
    ask_database_external
    CONFIGURE_DBHOST=true
  fi
}

ask_database_external() {
  echo -n "* Do you want to configure MySQL to be accessed externally? (y/N): "
  read -r CONFIRM_DBEXTERNAL

  if [[ "$CONFIRM_DBEXTERNAL" =~ [Yy] ]]; then
    echo -n "* Enter the panel address (blank for any address): "
    read -r CONFIRM_DBEXTERNAL_HOST
    if [ "$CONFIRM_DBEXTERNAL_HOST" == "" ]; then
      MYSQL_DBHOST_HOST="%"
    else
      MYSQL_DBHOST_HOST="$CONFIRM_DBEXTERNAL_HOST"
    fi
    [ "$CONFIGURE_FIREWALL" == true ] && ask_database_firewall
    return 0
  fi
}

ask_database_firewall() {
  warning "Allow incoming traffic to port 3306 (MySQL) can potentially be a security risk, unless you know what you are doing!"
  echo -n "* Would you like to allow incoming traffic to port 3306? (y/N): "
  read -r CONFIRM_DB_FIREWALL
  if [[ "$CONFIRM_DB_FIREWALL" =~ [Yy] ]]; then
    CONFIGURE_DB_FIREWALL=true
  fi
}

ask_node_configuration() {
  output ""
  output "Auto Node Configuration"
  output "This feature allows you to automatically configure Wings by connecting to your panel."
  output "You need to first create a node in the panel and get the auto-deploy token."
  output "You can find this by going to Admin -> Nodes -> [Your Node] -> Configuration -> Generate Token"
  output ""

  echo -n "* Do you want to automatically configure this node with your panel? (y/N): "
  read -r CONFIRM_NODE

  if [[ "$CONFIRM_NODE" =~ [Yy] ]]; then
    CONFIGURE_NODE=true

    output ""
    output "You can either:"
    output "  [1] Paste the full auto-deploy command from the panel"
    output "  [2] Enter the panel URL and token separately"
    output ""
    echo -n "* Choose an option (1/2): "
    read -r INPUT_METHOD

    local MAX_RETRIES=5
    local total_retry_count=0
    local NODE_ID=""

    if [[ "$INPUT_METHOD" == "1" ]]; then
      # Option 1: Parse full auto-deploy command
      output ""
      output "Paste the full auto-deploy command from the panel."
      output "Example: cd /etc/pterodactyl && sudo wings configure --panel-url https://panel.example.com --token ptla_xxx --node 1"
      output ""
      
      while [ -z "$PANEL_URL" ] || [ -z "$NODE_TOKEN" ]; do
        echo -n "* Paste the auto-deploy command: "
        read -r AUTODEPLOY_CMD

        if [ -z "$AUTODEPLOY_CMD" ]; then
          error "Command cannot be empty"
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
          continue
        fi

        # Reset variables before parsing
        PANEL_URL=""
        NODE_TOKEN=""

        # Parse panel URL from the command
        if [[ "$AUTODEPLOY_CMD" =~ --panel-url[[:space:]]+([^[:space:]]+) ]]; then
          PANEL_URL="${BASH_REMATCH[1]}"
        else
          error "Could not extract panel URL from the command"
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
          continue
        fi

        # Parse token from the command
        if [[ "$AUTODEPLOY_CMD" =~ --token[[:space:]]+([^[:space:]]+) ]]; then
          NODE_TOKEN="${BASH_REMATCH[1]}"
        else
          error "Could not extract token from the command"
          PANEL_URL=""
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
          continue
        fi

        # Parse node ID from the command (optional, for display purposes)
        if [[ "$AUTODEPLOY_CMD" =~ --node[[:space:]]+([0-9]+) ]]; then
          NODE_ID="${BASH_REMATCH[1]}"
          output "Detected Node ID: $NODE_ID"
        fi

        # Validate extracted values
        if [ -z "$PANEL_URL" ] || [ -z "$NODE_TOKEN" ]; then
          error "Failed to parse the auto-deploy command. Please check the format."
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
          continue
        fi

        success "Successfully parsed auto-deploy command!"
        output "  Panel URL: $PANEL_URL"
        output "  Token: ${NODE_TOKEN:0:10}... (hidden)"
      done
    else
      # Option 2: Manual entry
      # Get Panel URL
      while [ -z "$PANEL_URL" ]; do
        echo -n "* Enter the panel URL (e.g., https://panel.example.com): "
        read -r PANEL_URL

        if [ -z "$PANEL_URL" ]; then
          error "Panel URL cannot be empty"
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
        fi
      done

      # Get auto-deploy token
      while [ -z "$NODE_TOKEN" ]; do
        echo -n "* Enter the auto-deploy token from the panel: "
        read -r NODE_TOKEN

        if [ -z "$NODE_TOKEN" ]; then
          error "Token cannot be empty"
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
        fi
      done
    fi

    # Common validation for both methods with retry support
    while true; do
      # Validate URL format
      if [[ ! "$PANEL_URL" =~ ^https?:// ]]; then
        error "Panel URL must start with http:// or https://"
        total_retry_count=$((total_retry_count + 1))
        if [ $total_retry_count -ge $MAX_RETRIES ]; then
          error "Maximum retry attempts reached. Aborting auto-configuration."
          PANEL_URL=""
          NODE_TOKEN=""
          CONFIGURE_NODE=false
          return 1
        fi
        echo -n "* Enter the panel URL (e.g., https://panel.example.com): "
        read -r PANEL_URL
        [ -z "$PANEL_URL" ] && continue
        continue
      fi

      # Remove trailing slash if present
      PANEL_URL="${PANEL_URL%/}"

      # Check if panel is reachable
      output "Verifying panel connectivity..."
      if ! curl -sSf --connect-timeout 10 --max-redirs 3 "$PANEL_URL" >/dev/null 2>&1; then
        warning "Could not contact the panel at $PANEL_URL (network issue or HTTP error response)"
        echo -n "* Do you want to continue anyway? (y/N): "
        read -r CONTINUE_ANYWAY
        if [[ ! "$CONTINUE_ANYWAY" =~ [Yy] ]]; then
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
          echo -n "* Enter a different panel URL (e.g., https://panel.example.com): "
          read -r PANEL_URL
          # Force re-validation if empty
          [ -z "$PANEL_URL" ] && PANEL_URL=""
          continue
        fi
      else
        success "Panel is reachable!"
      fi

      # Validate token format (should start with ptla_ for application tokens)
      if [[ ! "$NODE_TOKEN" =~ ^ptla_ ]]; then
        warning "Token does not appear to be a valid auto-deploy token (should start with 'ptla_')"
        echo -n "* Do you want to continue anyway? (y/N): "
        read -r CONTINUE_TOKEN
        if [[ ! "$CONTINUE_TOKEN" =~ [Yy] ]]; then
          total_retry_count=$((total_retry_count + 1))
          if [ $total_retry_count -ge $MAX_RETRIES ]; then
            error "Maximum retry attempts reached. Aborting auto-configuration."
            PANEL_URL=""
            NODE_TOKEN=""
            CONFIGURE_NODE=false
            return 1
          fi
          echo -n "* Enter the auto-deploy token from the panel: "
          read -r NODE_TOKEN
          # Force re-validation if empty
          [ -z "$NODE_TOKEN" ] && NODE_TOKEN=""
          continue
        fi
      fi

      # All validations passed
      break
    done

    # Ask about SSL verification
    if [[ "$PANEL_URL" =~ ^https:// ]]; then
      output ""
      output "SSL Certificate Verification"
      warning "If your panel uses a self-signed certificate or has SSL issues, you may need to skip SSL verification."
      echo -n "* Do you want to allow insecure SSL connections (skip certificate verification)? (y/N): "
      read -r CONFIRM_INSECURE
      if [[ "$CONFIRM_INSECURE" =~ [Yy] ]]; then
        ALLOW_INSECURE=true
        warning "SSL certificate verification will be disabled. Use only in trusted environments!"
      fi
    fi

    # Final confirmation
    output ""
    output "Configuration Summary:"
    output "  Panel URL: $PANEL_URL"
    output "  Token: ${NODE_TOKEN:0:10}... (hidden)"
    [ -n "$NODE_ID" ] && output "  Node ID: $NODE_ID"
    if [ "$ALLOW_INSECURE" == true ]; then
      output "  Allow Insecure: yes"
    else
      output "  Allow Insecure: no"
    fi
  fi
}
ask_gameserver_ports() {
  echo -e -n "* Do you want to allow game server ports (19132/UDP for Minecraft Bedrock, 25500-25600/TCP+UDP)? (y/N): "
  read -r CONFIRM_GAMESERVER_PORTS
  if [[ "$CONFIRM_GAMESERVER_PORTS" =~ [Yy] ]]; then
    CONFIGURE_GAMESERVER_PORTS=true
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
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      error "Installation aborted!"
      exit 1
    fi
  fi

  welcome "wings"

  check_virt

  echo "* "
  echo "* The installer will install Docker, required dependencies for Wings"
  echo "* as well as Wings itself. You can optionally configure the node"
  echo "* automatically using the auto-deploy feature from your panel."
  echo "* Read more about this process on the"
  echo "* official documentation: $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  echo "* "
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not start Wings automatically (will install systemd service, not start it)."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not enable swap (for docker)."
  print_brake 42

  ask_firewall CONFIGURE_FIREWALL

  [ "$CONFIGURE_FIREWALL" == true ] && ask_gameserver_ports

  ask_database_user

  if [ "$CONFIGURE_DBHOST" == true ]; then
    type mysql >/dev/null 2>&1 && HAS_MYSQL=true || HAS_MYSQL=false

    if [ "$HAS_MYSQL" == false ]; then
      INSTALL_MARIADB=true
    fi

    MYSQL_DBHOST_USER="-"
    while [[ "$MYSQL_DBHOST_USER" == *"-"* ]]; do
      required_input MYSQL_DBHOST_USER "Database host username (pterodactyluser): " "" "pterodactyluser"
      [[ "$MYSQL_DBHOST_USER" == *"-"* ]] && error "Database user cannot contain hyphens"
    done

    password_input MYSQL_DBHOST_PASSWORD "Database host password: " "Password cannot be empty"
  fi

  ask_letsencrypt

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while [ -z "$FQDN" ]; do
      echo -n "* Set the FQDN to use for Let's Encrypt (node.example.com): "
      read -r FQDN

      ASK=false

      [ -z "$FQDN" ] && error "FQDN cannot be empty"                                                            # check if FQDN is empty
      bash <(curl -s "$GITHUB_URL"/lib/verify-fqdn.sh) "$FQDN" || ASK=true                                      # check if FQDN is valid
      [ -d "/etc/letsencrypt/live/$FQDN/" ] && error "A certificate with this FQDN already exists!" && ASK=true # check if cert exists

      [ "$ASK" == true ] && FQDN=""
      [ "$ASK" == true ] && echo -e -n "* Do you still want to automatically configure HTTPS using Let's Encrypt? (y/N): "
      [ "$ASK" == true ] && read -r CONFIRM_SSL

      if [[ ! "$CONFIRM_SSL" =~ [Yy] ]] && [ "$ASK" == true ]; then
        CONFIGURE_LETSENCRYPT=false
        FQDN=""
      fi
    done
  fi

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    # set EMAIL
    while ! valid_email "$EMAIL"; do
      echo -n "* Enter email address for Let's Encrypt: "
      read -r EMAIL

      valid_email "$EMAIL" || error "Email cannot be empty or invalid"
    done
  fi

  ask_node_configuration

  echo -n "* Proceed with installation? (y/N): "

  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
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

  if [ "$CONFIGURE_NODE" == true ]; then
    echo "* Node has been automatically configured with your panel!"
    echo "*"
    echo "* You can now start Wings manually to verify that it's working"
    echo "*"
    echo "* sudo wings"
    echo "*"
    echo "* Once you have verified that it is working, use CTRL+C and then start Wings as a service (runs in the background)"
    echo "*"
    echo "* systemctl start wings"
  else
    echo "* To continue, you need to configure Wings to run with your panel"
    echo "* Please refer to the official guide, $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
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
  fi

  echo "*"
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: It is recommended to enable swap (for Docker, read more about it in official documentation)."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured your firewall, ports 8080 and 2022 needs to be open."
  print_brake 70
  echo ""
}

# run script
main
goodbye
