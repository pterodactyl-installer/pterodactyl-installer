#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for panel                                 #
#                                                                           #
# Copyright (C) 2018 - 2021, Vilhelm Prytz, <vilhelm@prytznet.se>           #
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

######## General checks #########

# exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

# check for curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

########## Variables ############

#### Versions ####

SCRIPT_VERSION="v0.9.1"
PMA_VERSION="5.1.1"
GITHUB_SOURCE="master"

FQDN=""

# Directory for installing PMA #

DIR="/var/www/phpmyadmin"

# Default MySQL credentials

MYSQL_DB="phpmyadmin"
MYSQL_USER="phpmyadmin"
MYSQL_PASSWORD=""

# Environment

email=""

# Initial admin account

user_username=""
user_password=""

# Assume SSL, will fetch different config if true
ASSUME_SSL=false
CONFIGURE_LETSENCRYPT=false

# download URL

PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/$PMA_VERSION/phpMyAdmin-$PMA_VERSION-all-languages.tar.gz"
GITHUB_BASE_URL="https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/$GITHUB_SOURCE"

####### Visual functions ########

print_error() {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

print_warning() {
  COLOR_YELLOW='\033[1;33m'
  COLOR_NC='\033[0m'
  echo ""
  echo -e "* ${COLOR_YELLOW}WARNING${COLOR_NC}: $1"
  echo ""
}

print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

password_input() {
  local __resultvar=$1
  local result=''
  local default="$4"

  while [ -z "$result" ]; do
    echo -n "* ${2}"

    # modified from https://stackoverflow.com/a/22940001
    while IFS= read -r -s -n1 char; do
      [[ -z $char ]] && {
        printf '\n'
        break
      }                               # ENTER pressed; output \n and break.
      if [[ $char == $'\x7f' ]]; then # backspace was pressed
        # Only if variable is not empty
        if [ -n "$result" ]; then
          # Remove last char from output variable.
          [[ -n $result ]] && result=${result%?}
          # Erase '*' to the left.
          printf '\b \b'
        fi
      else
        # Add typed char to output variable.
        result+=$char
        # Print '*' in its stead.
        printf '*'
      fi
    done
    [ -z "$result" ] && [ -n "$default" ] && result="$default"
    [ -z "$result" ] && print_error "${3}"
  done

  eval "$__resultvar="'$result'""
}

##### User input functions ######

required_input() {
  local __resultvar=$1
  local result=''

  while [ -z "$result" ]; do
    echo -n "* ${2}"
    read -r result

    if [ -z "${3}" ]; then
      [ -z "$result" ] && result="${4}"
    else
      [ -z "$result" ] && print_error "${3}"
    fi
  done

  eval "$__resultvar="'$result'""
}

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    print_warning "Let's Encrypt requires port 80/443 to be opened! You have opted out of the automatic firewall configuration; use this at your own risk (if port 80/443 is closed, the script will fail)!"
  fi

  print_warning "You cannot use Let's Encrypt with your hostname as an IP address! It must be a FQDN (e.g. pma.example.org)."

  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=false
  fi
}

letsencrypt() {
  FAILED=false

  # Install certbot
  case "$OS" in
  debian | ubuntu)
    apt-get -y install certbot python3-certbot-nginx
    ;;
  centos)
    [ "$OS_VER_MAJOR" == "7" ] && yum -y -q install certbot python-certbot-nginx
    [ "$OS_VER_MAJOR" == "8" ] && dnf -y -q install certbot python3-certbot-nginx
    ;;
  esac

  # Obtain certificate
  certbot --nginx --redirect --no-eff-email --email "$email" -d "$FQDN" || FAILED=true

  # Check if it succeded
  if [ ! -d "/etc/letsencrypt/live/$FQDN/" ] || [ "$FAILED" == true ]; then
    print_warning "The process of obtaining a Let's Encrypt certificate failed!"
    echo -n "* Still assume SSL? (y/N): "
    read -r CONFIGURE_SSL

    if [[ "$CONFIGURE_SSL" =~ [Yy] ]]; then
      ASSUME_SSL=true
      CONFIGURE_LETSENCRYPT=false
      configure_nginx
    else
      ASSUME_SSL=false
      CONFIGURE_LETSENCRYPT=false
    fi
  fi
}

ask_assume_ssl() {
  echo "* Let's Encrypt is not going to be automatically configured by this script (user opted out)."
  echo "* You can 'assume' Let's Encrypt, which means the script will download a nginx configuration that is configured to use a Let's Encrypt certificate but the script won't obtain the certificate for you."
  echo "* If you assume SSL and do not obtain the certificate, your installation will not work."
  echo -n "* Assume SSL or not? (y/N): "
  read -r ASSUME_SSL_INPUT

  [[ "$ASSUME_SSL_INPUT" =~ [Yy] ]] && ASSUME_SSL=true
  true
}

ask_firewall() {
  case "$OS" in
  ubuntu | debian)
    echo -e -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
    read -r CONFIRM_UFW

    if [[ "$CONFIRM_UFW" =~ [Yy] ]]; then
      CONFIGURE_UFW=true
      CONFIGURE_FIREWALL=true
    fi
    ;;
  centos)
    echo -e -n "* Do you want to automatically configure firewall-cmd (firewall)? (y/N): "
    read -r CONFIRM_FIREWALL_CMD

    if [[ "$CONFIRM_FIREWALL_CMD" =~ [Yy] ]]; then
      CONFIGURE_FIREWALL_CMD=true
      CONFIGURE_FIREWALL=true
    fi
    ;;
  esac
}

firewall_ufw() {
  apt install -y ufw

  echo -e "\n* Enabling Uncomplicated Firewall (UFW)"
  echo "* Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

  # pointing to /dev/null silences the command output
  ufw allow ssh >/dev/null
  ufw allow http >/dev/null
  ufw allow https >/dev/null

  ufw --force enable
  ufw --force reload
  ufw status numbered | sed '/v6/d'
}

####### OS check funtions #######

detect_distro() {
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si | awk '{print tolower($0)}')
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID" | awk '{print tolower($0)}')
    OS_VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS="debian"
    OS_VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS="SuSE"
    OS_VER="?"
  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS="Red Hat/CentOS"
    OS_VER="?"
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    OS_VER=$(uname -r)
  fi

  OS=$(echo "$OS" | awk '{print tolower($0)}')
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

check_os_comp() {
  CPU_ARCHITECTURE=$(uname -m)
  if [ "${CPU_ARCHITECTURE}" != "x86_64" ]; then # check the architecture
    print_warning "Detected CPU architecture $CPU_ARCHITECTURE"
    print_warning "Using any other architecture than 64 bit (x86_64) will cause problems."

    echo -e -n "* Are you sure you want to proceed? (y/N):"
    read -r choice

    if [[ ! "$choice" =~ [Yy] ]]; then
      print_error "Installation aborted!"
      exit 1
    fi
  fi

  case "$OS" in
  ubuntu)
    PHP_SOCKET="/run/php/php8.0-fpm.sock"
    [ "$OS_VER_MAJOR" == "18" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "20" ] && SUPPORTED=true
    ;;
  debian)
    PHP_SOCKET="/run/php/php8.0-fpm.sock"
    [ "$OS_VER_MAJOR" == "9" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "10" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "11" ] && SUPPORTED=true
    ;;
  centos)
    PHP_SOCKET="/var/run/php-fpm/phpmyadmin.sock"
    [ "$OS_VER_MAJOR" == "7" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "8" ] && SUPPORTED=true
    ;;
  *)
    SUPPORTED=false
    ;;
  esac

  # exit if not supported
  if [ "$SUPPORTED" == true ]; then
    echo "* $OS $OS_VER is supported."
  else
    echo "* $OS $OS_VER is not supported"
    print_error "Unsupported OS"
    exit 1
  fi
}

# Create all necessary folders #

create_folders() {
mkdir -p /etc/phpmyadmin/upload
mkdir -p /etc/phpmyadmin/save
mkdir -p /etc/phpmyadmin/tmp
mkdir -p /var/www/phpmyadmin/tmp
}

# Define permisions #

define_permisions() {
chmod -R 660  /etc/phpmyadmin/*
chmod -R 777 /var/www/phpmyadmin/tmp
case "$OS" in
debian | ubuntu)
    chown -R www-data.www-data /var/www/phpmyadmin/*
    chown -R www-data.www-data /etc/phpmyadmin/*
;;
centos)
    chown -R nginx:nginx /var/www/phpmyadmin/*
    chown -R nginx:nginx /etc/phpmyadmin/*
;;
esac
}


# Download the PMA files #

pma_dl() {
echo "* Downloading the phpmyadmin files..."
cd /var/www/phpmyadmin || exit

curl -Lo phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz "$PMA_URL"
tar -xzvf phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PMA_VERSION}"-all-languages || exit
mv -- * "$DIR"
cd "$DIR" || exit
rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz && rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages && rm -r config.sample.inc.php
}

# Create a databse with user
create_database() {
  if [ "$OS" == "centos" ]; then
    # secure MariaDB
    echo "* MariaDB secure installation. The following are safe defaults."
    echo "* Set root password? [Y/n] Y"
    echo "* Remove anonymous users? [Y/n] Y"
    echo "* Disallow root login remotely? [Y/n] Y"
    echo "* Remove test database and access to it? [Y/n] Y"
    echo "* Reload privilege tables now? [Y/n] Y"
    echo "*"

    [ "$OS_VER_MAJOR" == "7" ] && mariadb-secure-installation
    [ "$OS_VER_MAJOR" == "8" ] && mysql_secure_installation

    echo "* The script should have asked you to set the MySQL root password earlier (not to be confused with the pterodactyl database user password)"
    echo "* MySQL will now ask you to enter the password before each command."

    echo "* Create MySQL user."
    mysql -u root -p -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    echo "* Create database."
    mysql -u root -p -e "CREATE DATABASE ${MYSQL_DB};"

    echo "* Grant privileges."
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION;"

    echo "* Flush privileges."
    mysql -u root -p -e "FLUSH PRIVILEGES;"
  else
    echo "* Performing MySQL queries.."

    echo "* Creating MySQL user.."
    mysql -u root -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    echo "* Creating database.."
    mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"

    echo "* Granting privileges.."
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION;"

    echo "* Flushing privileges.."
    mysql -u root -e "FLUSH PRIVILEGES;"

    echo "* MySQL database created & configured!"
  fi
}

# Configure environment
configure() {
  app_url="http://$FQDN"
  [ "$ASSUME_SSL" == true ] && app_url="https://$FQDN"
  [ "$CONFIGURE_LETSENCRYPT" == true ] && app_url="https://$FQDN"
}

##### WEBSERVER CONFIGURATION FUNCTIONS #####

configure_nginx() {
  echo "* Configuring nginx .."

  if [ $ASSUME_SSL == true ] && [ $CONFIGURE_LETSENCRYPT == false ]; then
    DL_FILE="nginx_ssl.conf"
  else
    DL_FILE="nginx.conf"
  fi

  if [ "$OS" == "centos" ]; then
    # remove default config
    rm -rf /etc/nginx/conf.d/default

    # download new config
    curl -o /etc/nginx/conf.d/pterodactyl.conf $GITHUB_BASE_URL/configs/$DL_FILE

    # replace all <domain> places with the correct domain
    sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/pterodactyl.conf

    # replace all <php_socket> places with correct socket "path"
    sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/conf.d/pterodactyl.conf
  else
    # remove default config
    rm -rf /etc/nginx/sites-enabled/default

    # download new config
    curl -o /etc/nginx/sites-available/pterodactyl.conf $GITHUB_BASE_URL/configs/$DL_FILE

    # replace all <domain> places with the correct domain
    sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-available/pterodactyl.conf

    # replace all <php_socket> places with correct socket "path"
    sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/sites-available/pterodactyl.conf

    # on debian 9, TLS v1.3 is not supported (see #76)
    [ "$OS" == "debian" ] && [ "$OS_VER_MAJOR" == "9" ] && sed -i 's/ TLSv1.3//' /etc/nginx/sites-available/pterodactyl.conf

    # enable pterodactyl
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  fi

  if [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ]; then
    systemctl restart nginx
  fi

  echo "* nginx configured!"
}

##### OS specific install functions #####

apt_update() {
  apt update -q -y && apt upgrade -y
}

yum_update() {
  yum -y update
}

dnf_update() {
  dnf -y upgrade
}

enable_services_debian_based() {
  systemctl enable mariadb
  systemctl start mariadb
}

enable_services_centos_based() {
  systemctl enable mariadb
  systemctl enable nginx
  systemctl start mariadb
}

selinux_allow() {
  setsebool -P httpd_can_network_connect 1 || true # these commands can fail OK
  setsebool -P httpd_execmem 1 || true
  setsebool -P httpd_unified 1 || true
}

ubuntu20_dep() {
  echo "* Installing dependencies for Ubuntu 20.."

  # Add "add-apt-repository" command
  apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

  # Ubuntu universe repo
  add-apt-repository universe

  # Add PPA for PHP (we need 8.0 and focal only has 7.4)
  LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

  # Update repositories list
  apt_update

  # Install Dependencies
  apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

  # Enable services
  enable_services_debian_based

  echo "* Dependencies for Ubuntu installed!"
}

ubuntu18_dep() {
  echo "* Installing dependencies for Ubuntu 18.."

  # Add "add-apt-repository" command
  apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

  # Ubuntu universe repo
  add-apt-repository universe

  # Add PPA for PHP (we need 8.0 and bionic only has 7.2)
  LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

  # Add the MariaDB repo (bionic has mariadb version 10.1 and we need newer than that)
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # Update repositories list
  apt_update

  # Install Dependencies
  apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

  # Enable services
  enable_services_debian_based

  echo "* Dependencies for Ubuntu installed!"
}

debian_stretch_dep() {
  echo "* Installing dependencies for Debian 8/9.."

  # MariaDB need dirmngr
  apt -y install dirmngr

  # install PHP 8.0 using sury's repo instead of PPA
  apt install ca-certificates apt-transport-https lsb-release -y
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

  # Add the MariaDB repo (oldstable has mariadb version 10.1 and we need newer than that)
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

  # Update repositories list
  apt_update

  # Install Dependencies
  apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

  # Enable services
  enable_services_debian_based

  echo "* Dependencies for Debian 8/9 installed!"
}

debian_buster_dep() {
  echo "* Installing dependencies for Debian 10.."

  # MariaDB need dirmngr
  apt -y install dirmngr

  # install PHP 8.0 using sury's repo instead of default 7.2 package (in buster repo)
  # this guide shows how: https://vilhelmprytz.se/2018/08/22/install-php72-on-Debian-8-and-9.html
  apt install ca-certificates apt-transport-https lsb-release -y
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

  # Update repositories list
  apt_update

  # install dependencies
  apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

  # Enable services
  enable_services_debian_based

  echo "* Dependencies for Debian 10 installed!"
}

debian_dep() {
  echo "* Installing dependencies for Debian 11.."

  # MariaDB need dirmngr
  apt -y install dirmngr

  # install PHP 8.0 using sury's repo instead of default 7.2 package (in buster repo)
  # this guide shows how: https://vilhelmprytz.se/2018/08/22/install-php72-on-Debian-8-and-9.html
  apt install ca-certificates apt-transport-https lsb-release -y
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

  # Update repositories list
  apt_update

  # install dependencies
  apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

  # Enable services
  enable_services_debian_based

  echo "* Dependencies for Debian 11 installed!"
}

centos7_dep() {
  echo "* Installing dependencies for CentOS 7.."

  # SELinux tools
  yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans

  # Add remi repo (php8.0)
  yum install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-7.rpm
  yum install -y yum-utils
  yum-config-manager -y --disable remi-php54
  yum-config-manager -y --enable remi-php80
  yum_update

  # Install MariaDB
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # Install dependencies
  yum -y install php php-common php-tokenizer php-curl php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server nginx

  # Enable services
  enable_services_centos_based

  # SELinux (allow nginx and redis)
  selinux_allow

  echo "* Dependencies for CentOS installed!"
}

centos8_dep() {
  echo "* Installing dependencies for CentOS 8.."

  # SELinux tools
  dnf install -y policycoreutils selinux-policy selinux-policy-targeted setroubleshoot-server setools setools-console mcstrans

  # add remi repo (php8.0)
  dnf install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-8.rpm
  dnf module enable -y php:remi-8.0
  dnf_update

  dnf install -y php php-common php-fpm php-cli php-json php-mysqlnd php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache

  # MariaDB (use from official repo)
  dnf install -y mariadb mariadb-server

  # Other dependencies
  dnf install -y nginx

  # Enable services
  enable_services_centos_based

  # SELinux (allow nginx and redis)
  selinux_allow

  echo "* Dependencies for CentOS installed!"
}

perform_install() {
  echo "* Starting installation.. this might take a while!"

  case "$OS" in
  debian | ubuntu)
    apt_update

    [ "$CONFIGURE_UFW" == true ] && firewall_ufw

    if [ "$OS" == "ubuntu" ]; then
      [ "$OS_VER_MAJOR" == "20" ] && ubuntu20_dep
      [ "$OS_VER_MAJOR" == "18" ] && ubuntu18_dep
    elif [ "$OS" == "debian" ]; then
      [ "$OS_VER_MAJOR" == "9" ] && debian_stretch_dep
      [ "$OS_VER_MAJOR" == "10" ] && debian_buster_dep
      [ "$OS_VER_MAJOR" == "11" ] && debian_dep
    fi
    ;;

  centos)
    [ "$OS_VER_MAJOR" == "7" ] && yum_update
    [ "$OS_VER_MAJOR" == "8" ] && dnf_update

    [ "$CONFIGURE_FIREWALL_CMD" == true ] && firewall_firewalld

    [ "$OS_VER_MAJOR" == "7" ] && centos7_dep
    [ "$OS_VER_MAJOR" == "8" ] && centos8_dep
    ;;
  esac

  [ "$OS" == "centos" ] && centos_php
  create_folders
  define_permisions
  pma_dl
  create_database
  configure
  configure_nginx
  [ "$CONFIGURE_LETSENCRYPT" == true ] && letsencrypt
  true
}

main() {
# Check if there is already an installation #
    if [ -d "/var/www/phpmyadmin" ]; then
        print_warning "The script has detected that you already have PhpMyAdmin panel on your system! You cannot run the script multiple times, it will fail!"
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
  echo "* Pterodactyl panel installation script @ $SCRIPT_RELEASE"
  echo "*"
  echo "* Copyright (C) 2018 - 2021, Vilhelm Prytz, <vilhelm@prytznet.se>"
  echo "* https://github.com/vilhelmprytz/pterodactyl-installer"
  echo "*"
  echo "* This script is not associated with the official Pterodactyl Project."
  echo "*"
  echo "* Running $OS version $OS_VER."
  echo "* Latest pterodactyl/panel is $PTERODACTYL_VERSION"
  print_brake 70

  # checks if the system is compatible with this installation script
  check_os_comp

  # set database credentials
  print_brake 72
  echo "* Database configuration."
  echo ""
  echo "* This will be the credentials used for communication between the MySQL"
  echo "* database and the panel. You do not need to create the database"
  echo "* before running this script, the script will do that for you."
  echo ""

  MYSQL_DB="-"
  while [[ "$MYSQL_DB" == *"-"* ]]; do
    required_input MYSQL_DB "Database name (pma): " "" "pma"
    [[ "$MYSQL_DB" == *"-"* ]] && print_error "Database name cannot contain hyphens"
  done

  MYSQL_USER="-"
  while [[ "$MYSQL_USER" == *"-"* ]]; do
    required_input MYSQL_USER "Database username (phpmyadmin): " "" "phpmyadmin"
    [[ "$MYSQL_USER" == *"-"* ]] && print_error "Database user cannot contain hyphens"
  done

  # MySQL password input
  rand_pw=$(
    tr -dc 'A-Za-z0-9!"#$%&()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 64
    echo
  )
  password_input MYSQL_PASSWORD "Password (press enter to use randomly generated password): " "MySQL password cannot be empty" "$rand_pw"

  # Initial admin account

  required_input user_username "Username for the initial admin account: " "Username cannot be empty"
  password_input user_password "Password for the initial admin account: " "Password cannot be empty"

  # set FQDN
  while [ -z "$FQDN" ]; do
    echo -n "* Set the FQDN of PhpMyAdmin (pma.example.com): "
    read -r FQDN
    [ -z "$FQDN" ] && print_error "FQDN cannot be empty"
  done

  # Ask if firewall is needed
  ask_firewall

  # Ask if letsencrypt is needed
  ask_letsencrypt

  # If it's already true, this should be a no-brainer
  [ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl

  # verify FQDN if user has selected to assume SSL or configure Let's Encrypt
  [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ] && bash <(curl -s $GITHUB_BASE_URL/lib/verify-fqdn.sh) "$FQDN" "$OS"

  # summary
  summary

  # confirm installation
  echo -e -n "\n* Initial configuration completed. Continue with installation? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    perform_install
  else
    # run welcome script again
    print_error "Installation aborted."
    exit 1
  fi
}

summary() {
  print_brake 62
  echo "* Web Server: Nginx"
  echo "* OS: $OS"
  echo "* Database name: $MYSQL_DB"
  echo "* Database user: $MYSQL_USER"
  echo "* Database password: (censored)"
  echo "* Username: $user_username"
  echo "* User password: (censored)"
  echo "* Hostname/FQDN: $FQDN"
  echo "* Configure Firewall? $CONFIGURE_FIREWALL"
  echo "* Configure Let's Encrypt? $CONFIGURE_LETSENCRYPT"
  echo "* Assume SSL? $ASSUME_SSL"
  print_brake 62
}

goodbye() {
  print_brake 62
  echo "* PhpMyAdmin installation completed"
  echo "*"

  [ "$CONFIGURE_LETSENCRYPT" == true ] && echo "* Your PMA should be accessible from $(hyperlink "$app_url")"
  [ "$ASSUME_SSL" == true ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && echo "* You have opted in to use SSL, but not via Let's Encrypt automatically. Your panel will not work until SSL has been configured."
  [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && echo "* Your panel should be accessible from $(hyperlink "$app_url")"

  echo "*"
  echo "* Installation is using nginx on $OS"
  echo "* Thank you for using this script."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured the firewall: 80/443 (HTTP/HTTPS) is required to be open!"
  print_brake 62
}

# run script
main
goodbye
