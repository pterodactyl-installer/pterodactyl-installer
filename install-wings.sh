#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for wings                                 #
#                                                                           #
# Copyright (C) 2018 - 2022, Vilhelm Prytz, <vilhelm@prytznet.se>           #
#                                                                           #
#   This program is free software: you can redistribute it and/or modify    #
#   it under the terms of the GNU General Public License as published by    #
#   the Free Software Foundation, either version 3 of the License, or       #
#   (at your option) any later version.                                     #
#                                                                           #
#   This program is distributed in the hope that it will be useful,         #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of          #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
#   GNU General Public License for more details.                            #
#                                                                           #
#   You should have received a copy of the GNU General Public License       #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.  #
#                                                                           #
# https://github.com/vilhelmprytz/pterodactyl-installer/blob/master/LICENSE #
#                                                                           #
# This script is not associated with the official Pterodactyl Project.      #
# https://github.com/vilhelmprytz/pterodactyl-installer                     #
#                                                                           #
#############################################################################

# TODO: Change to something like
# source /tmp/lib.sh || source <(curl -sL https://raw.githubuserc.com/vilhelmprytz/pterodactyl-installer/master/lib.sh)
# When released
# shellcheck source=lib.sh
source lib.sh


############################
## INSTALLATION FUNCTIONS ##
############################

apt_update() {
  apt update -q -y && apt upgrade -y
}

yum_update() {
  yum -y update
}

dnf_update() {
  dnf -y upgrade
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
    if [ "$CONFIRM_DBEXTERNAL_HOST" != "" ]; then
      CONFIGURE_DBEXTERNAL_HOST="$CONFIRM_DBEXTERNAL_HOST"
    fi
    [ "$CONFIGURE_FIREWALL" == true ] && ask_database_firewall
    CONFIGURE_DBEXTERNAL=true
  fi
}

ask_database_firewall() {
  print_warning "Allow incoming traffic to port 3306 (MySQL) can potentially be a security risk, unless you know what you are doing!"
  echo -n "* Would you like to allow incoming traffic to port 3306? (y/N): "
  read -r CONFIRM_DB_FIREWALL
  if [[ "$CONFIRM_DB_FIREWALL" =~ [Yy] ]]; then
    CONFIGURE_DB_FIREWALL=true
  fi
}

configure_mysql() {
  echo "* Performing MySQL queries.."

  if [ "$CONFIGURE_DBEXTERNAL" == true ]; then
    echo "* Creating MySQL user..."
    mysql -u root -e "CREATE USER '${MYSQL_DBHOST_USER}'@'${CONFIGURE_DBEXTERNAL_HOST}' IDENTIFIED BY '${MYSQL_DBHOST_PASSWORD}';"

    echo "* Granting privileges.."
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_DBHOST_USER}'@'${CONFIGURE_DBEXTERNAL_HOST}' WITH GRANT OPTION;"
  else
    echo "* Creating MySQL user..."
    mysql -u root -e "CREATE USER '${MYSQL_DBHOST_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_DBHOST_PASSWORD}';"

    echo "* Granting privileges.."
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_DBHOST_USER}'@'127.0.0.1' WITH GRANT OPTION;"
  fi

  echo "* Flushing privileges.."
  mysql -u root -e "FLUSH PRIVILEGES;"

  echo "* Changing MySQL bind address.."

  if [ "$CONFIGURE_DBEXTERNAL" == true ]; then
    case "$OS" in
    debian | ubuntu)
      sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf
      ;;
    centos)
      sed -ne 's/^#bind-address=0.0.0.0$/bind-address=0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf
      ;;
    esac
  
    systemctl restart mysqld
  fi

  echo "* MySQL configured!"
}

#################################
##### OS SPECIFIC FUNCTIONS #####
#################################

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    print_warning "Let's Encrypt requires port 80/443 to be opened! You have opted out of the automatic firewall configuration; use this at your own risk (if port 80/443 is closed, the script will fail)!"
  fi

  print_warning "You cannot use Let's Encrypt with your hostname as an IP address! It must be a FQDN (e.g. node.example.org)."

  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
  fi
}

firewall_ufw() {
  apt install ufw -y

  echo -e "\n* Enabling Uncomplicated Firewall (UFW)"
  echo "* Opening port 22 (SSH), 8080 (Wings Port), 2022 (Wings SFTP Port)"

  # pointing to /dev/null silences the command output
  ufw allow ssh >/dev/null
  ufw allow 8080 >/dev/null
  ufw allow 2022 >/dev/null

  [ "$CONFIGURE_LETSENCRYPT" == true ] && ufw allow http >/dev/null
  [ "$CONFIGURE_LETSENCRYPT" == true ] && ufw allow https >/dev/null
  [ "$CONFIGURE_DB_FIREWALL" == true ] && ufw allow 3306 >/dev/null

  ufw --force enable
  ufw --force reload
  ufw status numbered | sed '/v6/d'
}

firewall_firewalld() {
  echo -e "\n* Enabling firewall_cmd (firewalld)"
  echo "* Opening port 22 (SSH), 8080 (Wings Port), 2022 (Wings SFTP Port)"

  # Install
  [ "$OS_VER_MAJOR" == "7" ] && yum -y -q install firewalld >/dev/null
  [ "$OS_VER_MAJOR" == "8" ] && dnf -y -q install firewalld >/dev/null

  # Enable
  systemctl --now enable firewalld >/dev/null # Enable and start

  # Configure
  firewall-cmd --add-service=ssh --permanent -q                                           # Port 22
  firewall-cmd --add-port 8080/tcp --permanent -q                                         # Port 8080
  firewall-cmd --add-port 2022/tcp --permanent -q                                         # Port 2022
  [ "$CONFIGURE_LETSENCRYPT" == true ] && firewall-cmd --add-service=http --permanent -q  # Port 80
  [ "$CONFIGURE_LETSENCRYPT" == true ] && firewall-cmd --add-service=https --permanent -q # Port 443
  [ "$CONFIGURE_DB_FIREWALL" == true ] && firewall-cmd --add-service=mysql --permanent -q # Port 3306

  firewall-cmd --permanent --zone=trusted --change-interface=pterodactyl0 -q
  firewall-cmd --zone=trusted --add-masquerade --permanent
  firewall-cmd --reload -q # Enable firewall

  echo "* Firewall-cmd installed"
  print_brake 70
}

letsencrypt() {
  FAILED=false

  # Install certbot
  case "$OS" in
  debian | ubuntu)
    apt-get -y install certbot python3-certbot-nginx
    ;;
  centos)
    [ "$OS_VER_MAJOR" == "7" ] && yum -y -q install epel-release
    [ "$OS_VER_MAJOR" == "7" ] && yum -y -q install certbot python-certbot-nginx

    [ "$OS_VER_MAJOR" == "8" ] && dnf -y -q install epel-release
    [ "$OS_VER_MAJOR" == "8" ] && dnf -y -q install certbot python3-certbot-nginx
    ;;
  esac

  # If user has nginx
  systemctl stop nginx || true

  # Obtain certificate
  certbot certonly --no-eff-email --email "$EMAIL" --standalone -d "$FQDN" || FAILED=true

  systemctl start nginx || true

  # Check if it succeded
  if [ ! -d "/etc/letsencrypt/live/$FQDN/" ] || [ "$FAILED" == true ]; then
    print_warning "The process of obtaining a Let's Encrypt certificate failed!"
  fi
}

####################
## MAIN FUNCTIONS ##
####################

perform_install() {
  echo "* Installing pterodactyl wings.."
  [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] && apt_update
  [ "$OS" == "centos" ] && [ "$OS_VER_MAJOR" == "7" ] && yum_update
  [ "$OS" == "centos" ] && [ "$OS_VER_MAJOR" == "8" ] && dnf_update
  [ "$CONFIGURE_UFW" == true ] && firewall_ufw
  [ "$CONFIGURE_FIREWALL_CMD" == true ] && firewall_firewalld
  install_docker
  ptdl_dl
  systemd_file
  [ "$INSTALL_MARIADB" == true ] && install_mariadb
  [ "$CONFIGURE_DBHOST" == true ] && configure_mysql
  [ "$CONFIGURE_LETSENCRYPT" == true ] && letsencrypt

  # return true if script has made it this far
  return 0
}

main() {
  # check if we can detect an already existing installation
  if [ -d "/etc/pterodactyl" ]; then
    print_warning "The script has detected that you already have Pterodactyl wings on your system! You cannot run the script multiple times, it will fail!"
    echo -e -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      print_error "Installation aborted!"
      exit 1
    fi
  fi

  # detect distro
  detect_distro

  print_brake 70
  echo "* Pterodactyl Wings installation script @ $SCRIPT_RELEASE"
  echo "*"
  echo "* Copyright (C) 2018 - 2022, Vilhelm Prytz, <vilhelm@prytznet.se>"
  echo "* https://github.com/vilhelmprytz/pterodactyl-installer"
  echo "*"
  echo "* This script is not associated with the official Pterodactyl Project."
  echo "*"
  echo "* Running $OS version $OS_VER."
  echo "* Latest pterodactyl/wings is $WINGS_VERSION"
  print_brake 70

  # checks if the system is compatible with this installation script
  check_os_comp

  echo "* "
  echo "* The installer will install Docker, required dependencies for Wings"
  echo "* as well as Wings itself. But it's still required to create the node"
  echo "* on the panel and then place the configuration file on the node manually after"
  echo "* the installation has finished. Read more about this process on the"
  echo "* official documentation: $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  echo "* "
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not start Wings automatically (will install systemd service, not start it)."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not enable swap (for docker)."
  print_brake 42

  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    echo -e -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
    read -r CONFIRM_UFW

    if [[ "$CONFIRM_UFW" =~ [Yy] ]]; then
      CONFIGURE_UFW=true
      CONFIGURE_FIREWALL=true
    fi
  fi

  if [ "$OS" == "centos" ]; then
    echo -e -n "* Do you want to automatically configure firewall-cmd (firewall)? (y/N): "
    read -r CONFIRM_FIREWALL_CMD

    if [[ "$CONFIRM_FIREWALL_CMD" =~ [Yy] ]]; then
      CONFIGURE_FIREWALL_CMD=true
      CONFIGURE_FIREWALL=true
    fi
  fi

  ask_database_user

  if [ "$CONFIGURE_DBHOST" == true ]; then
    type mysql >/dev/null 2>&1 && HAS_MYSQL=true || HAS_MYSQL=false

    if [ "$HAS_MYSQL" == false ]; then
      INSTALL_MARIADB=true
    fi

    MYSQL_DBHOST_USER="-"
    while [[ "$MYSQL_DBHOST_USER" == *"-"* ]]; do
      required_input MYSQL_DBHOST_USER "Database host username (pterodactyluser): " "" "pterodactyluser"
      [[ "$MYSQL_DBHOST_USER" == *"-"* ]] && print_error "Database user cannot contain hyphens"
    done

    password_input MYSQL_DBHOST_PASSWORD "Database host password: " "Password cannot be empty"
  fi

  ask_letsencrypt

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while [ -z "$FQDN" ]; do
      echo -n "* Set the FQDN to use for Let's Encrypt (node.example.com): "
      read -r FQDN

      ASK=false

      [ -z "$FQDN" ] && print_error "FQDN cannot be empty"                                                            # check if FQDN is empty
      bash <(curl -s "$GITHUB_BASE_URL"/lib/verify-fqdn.sh) "$FQDN" "$OS" || ASK=true                                   # check if FQDN is valid
      [ -d "/etc/letsencrypt/live/$FQDN/" ] && print_error "A certificate with this FQDN already exists!" && ASK=true # check if cert exists

      [ "$ASK" == true ] && FQDN=""
      [ "$ASK" == true ] && echo -e -n "* Do you still want to automatically configure HTTPS using Let's Encrypt? (y/N): "
      [ "$ASK" == true ] && read -r CONFIRM_SSL

      if [[ ! "$CONFIRM_SSL" =~ [Yy] ]] && [ "$ASK" == true ]; then
        CONFIGURE_LETSENCRYPT=false
        FQDN="none"
      fi
    done
  fi

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    # set EMAIL
    while ! valid_email "$EMAIL"; do
      echo -n "* Enter email address for Let's Encrypt: "
      read -r EMAIL

      valid_email "$EMAIL" || print_error "Email cannot be empty or invalid"
    done
  fi

  echo -n "* Proceed with installation? (y/N): "

  read -r CONFIRM
  [[ "$CONFIRM" =~ [Yy] ]] && perform_install && return

  print_error "Installation aborted"
  exit 0
}

function goodbye {
  echo ""
  print_brake 70
  echo "* Wings installation completed"
  echo "*"
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
  echo "*"
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: It is recommended to enable swap (for Docker, read more about it in official documentation)."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured your firewall, ports 8080 and 2022 needs to be open."
  print_brake 70
  echo ""
}

# run script
main
goodbye
