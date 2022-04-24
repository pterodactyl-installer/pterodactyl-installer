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
# shellcheck source=lib.sh
source lib.sh

# ------------------ Variables ----------------- #

# Domain name / IP
FQDN=""

# Default MySQL credentials
MYSQL_DB="pterodactyl"
MYSQL_USER="pterodactyl"
MYSQL_PASSWORD=""

# Environment
email=""

# Initial admin account
user_email=""
user_username=""
user_firstname=""
user_lastname=""
user_password=""

# Assume SSL, will fetch different config if true
SSL_AVAILABLE=false
ASSUME_SSL=false
CONFIGURE_LETSENCRYPT=false

# ufw firewall
CONFIGURE_UFW=false

# firewall_cmd
CONFIGURE_FIREWALL_CMD=false

# firewall status
CONFIGURE_FIREWALL=false

# ---------------- Lib functions --------------- #

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

####### OS check funtions #######

check_os_comp() {
  if [ "${CPU_ARCHITECTURE}" != "x86_64" ]; then # check the architecture
    warning "Detected CPU architecture $CPU_ARCHITECTURE"
    warning "Using any other architecture than 64 bit (x86_64) will cause problems."

    echo -e -n "* Are you sure you want to proceed? (y/N):"
    read -r choice

    if [[ ! "$choice" =~ [Yy] ]]; then
      error "Installation aborted!"
      exit 1
    fi
  fi
}

##### Main installation functions #####

# Install composer
install_composer() {
  output "Installing composer.."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  output "Composer installed!"
}

# Download pterodactyl files
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

# Create a database with user
create_database() {
  local db_name="$1";
  local db_user_name="$2";
  local db_user_password="$3";
  local db_host="${4:-'127.0.0.0'}"

  output "Creating database $db_name with user $db_user_name..."

  output "Creating MySQL user.."
  mysql -u root -e "CREATE USER '$db_user_name'@'$db_host' IDENTIFIED BY '$db_user_password';"

  output "Creating database.."
  mysql -u root -e "CREATE DATABASE $db_name;"

  output "Granting privileges.."
  mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user_name'@'$db_host' WITH GRANT OPTION;"

  output "Flushing privileges.."
  mysql -u root -e "FLUSH PRIVILEGES;"

  output "MySQL database created & configured!"
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

# insert cronjob
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

php_fpm_conf() {
  curl -o /etc/php-fpm.d/www-pterodactyl.conf "$GITHUB_BASE_URL"/configs/www-pterodactyl.conf

  systemctl enable php-fpm
  systemctl start php-fpm
}

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
  create_database "$MYSQL_DB"" $MYSQL_USER" "$MYSQL_PASSWORD"
  configure
  set_folder_permissions
  insert_cronjob
  install_pteroq
  configure_nginx
  [ "$CONFIGURE_LETSENCRYPT" == true ] && letsencrypt
  true
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

  print_brake 70
  output "Pterodactyl panel installation script @ $SCRIPT_RELEASE"
  output ""
  output "Copyright (C) 2018 - 2022, Vilhelm Prytz, <vilhelm@prytznet.se>"
  output "https://github.com/vilhelmprytz/pterodactyl-installer"
  output ""
  output "This script is not associated with the official Pterodactyl Project."
  output ""
  output "Running $OS version $OS_VER."
  output "Latest pterodactyl/panel is $PTERODACTYL_PANEL_VERSION"
  print_brake 70

  # checks if the system is compatible with this installation script
  check_os_comp

  # set database credentials
  print_brake 72
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

  readarray -t valid_timezones <<< "$(curl -s "$GITHUB_BASE_URL"/configs/valid_timezones.txt)"
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
  ask_firewall

  # Only ask about SSL if it is available
  if [ "$SSL_AVAILABLE" == true ]; then
    # Ask if letsencrypt is needed
    ask_letsencrypt
    # If it's already true, this should be a no-brainer
    [ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl
  fi

  # verify FQDN if user has selected to assume SSL or configure Let's Encrypt
  [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ] && bash <(curl -s "$GITHUB_BASE_URL"/lib/verify-fqdn.sh) "$FQDN"

  # summary
  summary

  # confirm installation
  echo -e -n "\n* Initial configuration completed. Continue with installation? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    perform_install
  else
    # run welcome script again
    error "Installation aborted."
    exit 1
  fi
}

summary() {
  print_brake 62
  output "Pterodactyl panel $PTERODACTYL_VERSION with nginx on $OS"
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

  [ "$CONFIGURE_LETSENCRYPT" == true ] && output "Your panel should be accessible from $(hyperlink "$app_url")"
  [ "$ASSUME_SSL" == true ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "You have opted in to use SSL, but not via Let's Encrypt automatically. Your panel will not work until SSL has been configured."
  [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Your panel should be accessible from $(hyperlink "$app_url")"

  output ""
  output "Installation is using nginx on $OS"
  output "Thank you for using this script."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured the firewall: 80/443 (HTTP/HTTPS) is required to be open!"
  print_brake 62
}

# run script
main
goodbye
