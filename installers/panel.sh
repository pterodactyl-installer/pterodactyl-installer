#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for panel                                 #
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
# shellcheck source=../lib.sh
source ../lib/lib.sh

# ------------------ Variables ----------------- #

# Domain name / IP
FQDN="${FQDN:-localhost}"

# Default MySQL credentials
MYSQL_DB="${MYSQL_DB:-panel}"
MYSQL_USER="${MYSQL_USER:-pterodactyl}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-$(gen_passwd 64)}"

# Environment
email="${email:-}"
timezone="${timezone:-Europe/Stockholm}"

# Initial admin account
user_email="${user_email:-}"
user_username="${user_username:-}"
user_firstname="${user_firstname:-}"
user_lastname="${user_lastname:-}"
user_password="${user_password:-}"

# Assume SSL, will fetch different config if true
ASSUME_SSL="${ASSUME_SSL:-false}"
CONFIGURE_LETSENCRYPT="${CONFIGURE_LETSENCRYPT:-false}"

# Firewall
CONFIGURE_UFW="${CONFIGURE_UFW:-false}"
CONFIGURE_FIREWALL_CMD="${CONFIGURE_FIREWALL_CMD:-false}"

# Must be assigned to work
# email
# user_email
# user_username
# user_firstname
# user_lastname
# user_password

if [[ -z "${email}" ]]; then
    error "Email is required"
    exit 1
fi

if [[ -z "${user_email}" ]]; then
    error "User email is required"
    exit 1
fi

if [[ -z "${user_username}" ]]; then
    error "User username is required"
    exit 1
fi

if [[ -z "${user_firstname}" ]]; then
    error "User firstname is required"
    exit 1
fi

if [[ -z "${user_lastname}" ]]; then
    error "User lastname is required"
    exit 1
fi

if [[ -z "${user_password}" ]]; then
    error "User password is required"
    exit 1
fi

##### Main installation functions #####

install_composer() {
  output "Installing composer.."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  output "Composer installed!"
}

ptdl_dl() {
  output "Downloading pterodactyl panel files .. "
  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl || exit

  curl -Lo panel.tar.gz "$PANEL_DL_URL"
  tar -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/

  cp .env.example .env
  [ "$OS" == "centos" ] && export PATH=/usr/local/bin:$PATH
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

  php artisan key:generate --force
  output "Downloaded pterodactyl panel files & installed composer dependencies!"
}

# Configure environment
configure() {
  local app_url="http://$FQDN"
  [ "$ASSUME_SSL" == true ] && app_url="https://$FQDN"
  [ "$CONFIGURE_LETSENCRYPT" == true ] && app_url="https://$FQDN"

  # Fill in environment:setup automatically
  php artisan p:environment:setup \
    --author="$email" \
    --url="$app_url" \
    --timezone="$timezone" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="localhost" \
    --redis-pass="null" \
    --redis-port="6379" \
    --settings-ui=true

  # Fill in environment:database credentials automatically
  php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$MYSQL_DB" \
    --username="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD"

  # configures database
  php artisan migrate --seed --force

  # Create user account
  php artisan p:user:make \
    --email="$user_email" \
    --username="$user_username" \
    --name-first="$user_firstname" \
    --name-last="$user_lastname" \
    --password="$user_password" \
    --admin=1
}

# set the correct folder permissions depending on OS and webserver
set_folder_permissions() {
  # if os is ubuntu or debian, we do this
  case "$OS" in
  debian | ubuntu)
    chown -R www-data:www-data ./*
    ;;
  centos)
    chown -R nginx:nginx ./*
    ;;
  esac
}

insert_cronjob() {
  output "Installing cronjob.. "

  crontab -l | {
    cat
    output "* * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
  } | crontab -

  output "Cronjob installed!"
}

install_pteroq() {
  output "Installing pteroq service.."

  curl -o /etc/systemd/system/pteroq.service "$GITHUB_BASE_URL"/configs/pteroq.service

  case "$OS" in
  debian | ubuntu)
    sed -i -e "s@<user>@www-data@g" /etc/systemd/system/pteroq.service
    ;;
  centos)
    sed -i -e "s@<user>@nginx@g" /etc/systemd/system/pteroq.service
    ;;
  esac

  systemctl enable pteroq.service
  systemctl start pteroq

  output "Installed pteroq!"
}

##### OS specific install functions #####

enable_services() {
  case "$OS" in
  ubuntu | debian)
    systemctl enable redis-server
    systemctl start redis-server
    ;;
  rocky | almalinux | centos)
    systemctl enable redis
    systemctl start redis
    ;;
  esac
  systemctl enable nginx
  systemctl enable mariadb
  systemctl start mariadb
  
}

selinux_allow() {
  setsebool -P httpd_can_network_connect 1 || true # these commands can fail OK
  setsebool -P httpd_execmem 1 || true
  setsebool -P httpd_unified 1 || true
}

php_fpm_conf() {
  curl -o /etc/php-fpm.d/www-pterodactyl.conf "$GITHUB_BASE_URL"/configs/www-pterodactyl.conf

  systemctl enable php-fpm
  systemctl start php-fpm
}

ubuntu_dep() {
  # Install deps for adding repos
  install_packages "software-properties-common curl apt-transport-https ca-certificates gnupg"

  # Add Ubuntu universe repo
  add-apt-repository universe

  # Add PPA for PHP (we need 8.0)
  LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

  # Add the MariaDB repo (bionic has mariadb version 10.1 and we need newer than that)
  [ "$OS_VER_MAJOR" == "18" ] && curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

  true
}

debian_dep() {
  # Install deps for adding repos
  install_packages "dirmngr ca-certificates apt-transport-https lsb-release"

  # install PHP 8.0 using sury's repo
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

  # Add the MariaDB repo (oldstable has mariadb version 10.1 and we need newer than that)
  [ "$OS_VER_MAJOR" == "8" ] && curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

  true
}

centos_dep() {
  # SELinux tools
  install_packages "policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted \
    libselinux-utils setroubleshoot-server setools setools-console mcstrans"
  
  # Add remi repo (php8.0)
  install_packages "epel-release http://rpms.remirepo.net/enterprise/remi-release-7.rpm"
  install_packages "yum-utils"
  yum-config-manager -y --disable remi-php54
  yum-config-manager -y --enable remi-php80

  # Install MariaDB
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
}

alma_rocky_dep() {
  # SELinux tools
  install_packages "policycoreutils selinux-policy selinux-policy-targeted \
    setroubleshoot-server setools setools-console mcstrans"

  # add remi repo (php8.0)
  install_packages "epel-release http://rpms.remirepo.net/enterprise/remi-release-8.rpm"
  dnf module enable -y php:remi-8.0
}

dep_install() {
  output "Installing dependencies for $OS $OS_VER..."

  # Update repos before installing
  update_repos

  case "$OS" in
  ubuntu | debian)
    [ "$CONFIGURE_UFW" == true ] && firewall_ufw
    [ "$OS" == "ubuntu" ] && ubuntu_dep
    [ "$OS" == "debian" ] && debian_dep

    # Install dependencies
    install_packages "php8.0 php8.0-{cli,common,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} \
      mariadb-common mariadb-server mariadb-client \
      nginx \
      redis-server \
      zip unzip tar \
      git cron"

    ;;
  rocky | almalinux | centos)
    [ "$CONFIGURE_FIREWALL_CMD" == true ] && firewall_firewalld
    [ "$OS" == "centos" ] && centos_dep
    [ "$OS" == "almalinux" ] || [ "$OS" == "rocky" ] && alma_rocky_dep

    # Install dependencies
    install_packages "php php-{common,fpm,cli,json,mysqlnd,mcrypt,gd,mbstring,pdo,zip,bcmath,dom,opcache} \
      mariadb mariadb-server \
      nginx \
      redis \
      zip unzip tar \
      git cron"

    # Allow nginx
    selinux_allow

    # Create needed config for php fpm
    php_fpm_conf
    ;;
  esac

  enable_services
}

##### OTHER OS SPECIFIC FUNCTIONS #####

firewall_ufw() {
  install_packages "ufw"

  echo -e "\n* Enabling Uncomplicated Firewall (UFW)"
  output "Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

  # pointing to /dev/null silences the command output
  ufw allow ssh > /dev/null   # Port 22
  ufw allow http > /dev/null  # Port 80
  ufw allow https > /dev/null # Port 443

  ufw --force enable          # Enable firewall
  ufw --force reload
  ufw status numbered | sed '/v6/d'
}

firewall_firewalld() {
  echo -e "\n* Enabling firewall_cmd (firewalld)"
  output "Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

  # Install
  install_packages "firewalld"

  # Enable
  systemctl --now enable firewalld > /dev/null # Enable and start

  # Configure
  firewall-cmd --add-service=http --permanent -q  # Port 80
  firewall-cmd --add-service=https --permanent -q # Port 443
  firewall-cmd --add-service=ssh --permanent -q   # Port 22
  firewall-cmd --reload -q                        # Enable firewall

  output "Firewall-cmd installed"
  print_brake 70
}

letsencrypt() {
  FAILED=false

  # Install certbot
  case "$OS" in
  centos)
    install_packages "certbot python-certbot-nginx"
    ;;
  *)
    install_packages "certbot python3-certbot-nginx"
    ;;
  esac

  # Obtain certificate
  certbot --nginx --redirect --no-eff-email --email "$email" -d "$FQDN" || FAILED=true

  # Check if it succeded
  if [ ! -d "/etc/letsencrypt/live/$FQDN/" ] || [ "$FAILED" == true ]; then
    warning "The process of obtaining a Let's Encrypt certificate failed!"
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

##### WEBSERVER CONFIGURATION FUNCTIONS #####

configure_nginx() {
  output "Configuring nginx .."

  if [ $ASSUME_SSL == true ] && [ $CONFIGURE_LETSENCRYPT == false ]; then
    DL_FILE="nginx_ssl.conf"
  else
    DL_FILE="nginx.conf"
  fi

  case "$OS" in
  ubuntu | debian)
    PHP_SOCKET="/run/php/php8.0-fpm.sock"
    CONFIG_PATH_AVAIL="/etc/nginx/sites-available"
    CONFIG_PATH_ENABL="/etc/nginx/sites-enabled"
    ;;
  centos | rocky | almalinux)
    PHP_SOCKET="/var/run/php-fpm/pterodactyl.sock"
    CONFIG_PATH_AVAIL="/etc/nginx/conf.d"
    CONFIG_PATH_ENABL="$CONFIG_PATH_AVAIL"
    ;;
  esac

  rm -rf $CONFIG_PATH_ENABL/default

  curl -o $CONFIG_PATH_AVAIL/pterodactyl.conf "$GITHUB_BASE_URL"/configs/$DL_FILE

  sed -i -e "s@<domain>@${FQDN}@g" $CONFIG_PATH_AVAIL/pterodactyl.conf

  sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" $CONFIG_PATH_AVAIL/pterodactyl.conf

  [ "$OS" == "debian" ] && [ "$OS_VER_MAJOR" == "9" ] && sed -i 's/ TLSv1.3//' $CONFIG_PATH_AVAIL/pterodactyl.conf

  case "$OS" in
  ubuntu | debian)
    ln -sf $CONFIG_PATH_AVAIL/pterodactyl.conf $CONFIG_PATH_ENABL/pterodactyl.conf
  esac

  if [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ]; then
    systemctl restart nginx
  fi

  output "nginx configured!"
}

##### MAIN FUNCTIONS #####

perform_install() {
  output "Starting installation.. this might take a while!"
  dep_install
  install_composer
  ptdl_dl
  create_database "$MYSQL_DB""$MYSQL_USER" "$MYSQL_PASSWORD"
  configure
  set_folder_permissions
  insert_cronjob
  install_pteroq
  configure_nginx
  [ "$CONFIGURE_LETSENCRYPT" == true ] && letsencrypt
  true
}

# perform_install