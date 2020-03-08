#!/bin/bash

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for panel                                 #
#                                                                           #
# Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al.   #
#                                                                           #
# This script is licensed under the terms of the GNU GPL v3.0 license       #
# https://github.com/VilhelmPrytz/pterodactyl-installer/blob/master/LICENSE #
#                                                                           #
# This script is not associated with the official Pterodactyl Project.      #
# https://github.com/VilhelmPrytz/pterodactyl-installer                     #
#                                                                           #
#############################################################################

# exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

# check for curl
CURLPATH="$(command -v curl)"
if [ -z "$CURLPATH" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt on Debian/Ubuntu or yum on CentOS"
  exit 1
fi

# define version using information from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
  grep '"tag_name":' |                                              # Get tag line
  sed -E 's/.*"([^"]+)".*/\1/'                                      # Pluck JSON value
}

echo "* Retrieving release information.."
VERSION="$(get_latest_release "pterodactyl/panel")"
echo "* Latest version is $VERSION"

# variables
WEBSERVER="nginx"
FQDN=""

# default MySQL credentials
MYSQL_DB="pterodactyl"
MYSQL_USER="pterodactyl"
MYSQL_PASSWORD=""

# assume SSL, will fetch different config if true
ASSUME_SSL=false
CONFIGURE_LETSENCRYPT=false

# download URLs
PANEL_URL="https://github.com/pterodactyl/panel/releases/download/$VERSION/panel.tar.gz"
CONFIGS_URL="https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/configs"

# apt sources path
SOURCES_PATH="/etc/apt/sources.list"

# ufw firewall
CONFIGURE_UFW=false

# visual functions
function print_error {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

function print_brake {
  for ((n=0;n<$1;n++));
    do
      echo -n "#"
    done
    echo ""
}

# other functions
function detect_distro {
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

function check_os_comp {
  if [ "$OS" == "ubuntu" ]; then
    if [ "$OS_VER_MAJOR" == "16" ]; then
      SUPPORTED=true
      PHP_SOCKET="/run/php/php7.2-fpm.sock"
    elif [ "$OS_VER_MAJOR" == "18" ]; then
      SUPPORTED=true
      PHP_SOCKET="/run/php/php7.2-fpm.sock"
    else
      SUPPORTED=false
    fi
  elif [ "$OS" == "zorin" ]; then
    if [ "$OS_VER_MAJOR" == "15" ]; then
      SUPPORTED=true
      PHP_SOCKET="/run/php/php7.2-fpm.sock"
    else
      SUPPORTED=false
    fi
  elif [ "$OS" == "debian" ]; then
    if [ "$OS_VER_MAJOR" == "8" ]; then
      SUPPORTED=true
      PHP_SOCKET="/run/php/php7.3-fpm.sock"
    elif [ "$OS_VER_MAJOR" == "9" ]; then
      SUPPORTED=true
      PHP_SOCKET="/run/php/php7.3-fpm.sock"
    elif [ "$OS_VER_MAJOR" == "10" ]; then
      SUPPORTED=true
      PHP_SOCKET="/run/php/php7.3-fpm.sock"
    else
      SUPPORTED=false
    fi
  elif [ "$OS" == "centos" ]; then
    if [ "$OS_VER_MAJOR" == "7" ]; then
      SUPPORTED=true
      PHP_SOCKET="/var/run/php-fpm/pterodactyl.sock"
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      SUPPORTED=true
      PHP_SOCKET="/var/run/php-fpm/pterodactyl.sock"
    else
      SUPPORTED=false
    fi
  else
    SUPPORTED=false
  fi

  # exit if not supported
  if [ "$SUPPORTED" == true ]; then
    echo "* $OS $OS_VER is supported."
  else
    echo "* $OS $OS_VER is not supported"
    print_error "Unsupported OS"
    exit 1
  fi
}

#################################
## main installation functions ##
#################################

function install_composer {
  echo "* Installing composer.."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  echo "* Composer installed!"
}

function ptdl_dl {
  echo "* Downloading pterodactyl panel files .. "
  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl || exit

  curl -Lo panel.tar.gz "$PANEL_URL"
  tar --strip-components=1 -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/

  cp .env.example .env
  composer install --no-dev --optimize-autoloader

  php artisan key:generate --force
  echo "* Downloaded pterodactyl panel files & installed composer dependencies!"
}

function configure {
  print_brake 88
  echo "* Please follow the steps below. The installer will ask you for configuration details."
  print_brake 88
  echo ""
  php artisan p:environment:setup

  print_brake 67
  echo "* The installer will now ask you for MySQL database credentials."
  print_brake 67
  echo ""
  php artisan p:environment:database

  print_brake 70
  echo "* The installer will now ask you for mail setup / mail credentials."
  print_brake 70
  echo ""
  php artisan p:environment:mail

  # configures database
  php artisan migrate --seed

  echo "* The installer will now ask you to create the initial admin user account."
  php artisan p:user:make

  # set folder permissions now
  set_folder_permissions
}

# set the correct folder permissions depending on OS and webserver
function set_folder_permissions {
  # if os is ubuntu or debian, we do this
  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ]; then
    chown -R www-data:www-data ./*
  elif [ "$OS" == "centos" ] && [ "$WEBSERVER" == "nginx" ]; then
    chown -R nginx:nginx ./*
  elif [ "$OS" == "centos" ] && [ "$WEBSERVER" == "apache" ]; then
    chown -R apache:apache ./*
  else
    print_error "Invalid webserver and OS setup."
    exit 1
  fi
}

# insert cronjob
function insert_cronjob {
  echo "* Installing cronjob.. "

  crontab -l | { cat; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"; } | crontab -

  echo "* Cronjob installed!"
}

function install_pteroq {
  echo "* Installing pteroq service.."

  curl -o /etc/systemd/system/pteroq.service $CONFIGS_URL/pteroq.service
  systemctl enable pteroq.service
  systemctl start pteroq

  echo "* Installed pteroq!"
}

function create_database {
  if [ "$OS" == "centos" ]; then
    # secure MariaDB
    echo "* MariaDB secure installation. The following are safe defaults."
    echo "* Set root password? [Y/n] Y"
    echo "* Remove anonymous users? [Y/n] Y"
    echo "* Disallow root login remotely? [Y/n] Y"
    echo "* Remove test database and access to it? [Y/n] Y"
    echo "* Reload privilege tables now? [Y/n] Y"
    echo "*"

    mysql_secure_installation

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

##################################
# OS specific install functions ##
##################################

function apt_update {
  apt update -y && apt upgrade -y
}

function ubuntu18_dep {
  echo "* Installing dependencies for Ubuntu 18.."

  # Add "add-apt-repository" command
  apt -y install software-properties-common

  # Add additional repositories for PHP, Redis, and MariaDB
  add-apt-repository -y ppa:chris-lea/redis-server
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # Update repositories list
  apt update

  # Install Dependencies
  apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx curl tar unzip git redis-server

  systemctl start mariadb
  systemctl enable mariadb

  echo "* Dependencies for Ubuntu installed!"
}

function ubuntu16_dep {
  echo "* Installing dependencies for Ubuntu 16.."

  # Add "add-apt-repository" command
  apt -y install software-properties-common

  # Add additional repositories for PHP, Redis, and MariaDB
  LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
  add-apt-repository -y ppa:chris-lea/redis-server
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # Update repositories list
  apt update

  # Install Dependencies
  apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx curl tar unzip git redis-server

  systemctl start mariadb
  systemctl enable mariadb

  echo "* Dependencies for Ubuntu installed!"
}

function debian_jessie_dep {
  echo "* Installing dependencies for Debian 8/9.."

  # MariaDB need dirmngr
  apt -y install dirmngr

  # install PHP 7.3 using sury's repo instead of PPA
  # this guide shows how: https://vilhelmprytz.se/2018/08/22/install-php72-on-Debian-8-and-9.html 
  apt install ca-certificates apt-transport-https lsb-release -y
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

  # redis-server is not installed using the PPA, as it's already available in the Debian repo

  # Install MariaDb
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

  # Update repositories list
  apt update

  # Install Dependencies
  apt -y install php7.3 php7.3-cli php7.3-gd php7.3-mysql php7.3-pdo php7.3-mbstring php7.3-tokenizer php7.3-bcmath php7.3-xml php7.3-fpm php7.3-curl php7.3-zip mariadb-server nginx curl tar unzip git redis-server

  systemctl start mariadb
  systemctl enable mariadb

  echo "* Dependencies for Debian 8/9 installed!"
}

function debian_dep {
  echo "* Installing dependencies for Debian 10.."

  # MariaDB need dirmngr
  apt -y install dirmngr

  # Install MariaDb
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

  # Update repositories list
  apt update

  # install dependencies
  apt -y install php7.3 php7.3-cli php7.3-common php7.3-gd php7.3-mysql php7.3-mbstring php7.3-bcmath php7.3-xml php7.3-fpm php7.3-curl php7.3-zip mariadb-server nginx curl tar unzip git redis-server

  systemctl start mariadb
  systemctl enable mariadb

  echo "* Dependencies for Debian 10 installed!"
}

function centos7_dep {
  echo "* Installing dependencies for CentOS 7.."

  # update first
  yum update -y

  # SELinux tools
  yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans

  # install php7.3
  yum install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-7.rpm
  yum install -y yum-utils
  yum-config-manager --disable remi-php54
  yum-config-manager --enable remi-php73
  yum update -y

  # Install MariaDB
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # install dependencies
  yum -y install install php php-common php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server nginx curl tar zip unzip git redis

  # enable services
  systemctl enable mariadb
  systemctl enable redis
  systemctl start mariadb
  systemctl start redis

  # SELinux (allow nginx and redis)
  setsebool -P httpd_can_network_connect 1
  setsebool -P httpd_execmem 1
  setsebool -P httpd_unified 1

  echo "* Dependencies for CentOS installed!"
}

function centos8_dep {
  echo "* Installing dependencies for CentOS 8.."

  # update first
  dnf update -y

  # SELinux tools
  dnf install -y policycoreutils selinux-policy selinux-policy-targeted setroubleshoot-server setools setools-console mcstrans

  # Install php 7.2
  dnf install -y php php-common php-fpm php-cli php-json php-mysqlnd php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache

  # MariaDB (use from official repo)
  dnf install -y mariadb mariadb-server

  # Other dependencies
  dnf install -y nginx curl tar zip unzip git redis

  # enable services
  systemctl enable mariadb
  systemctl enable redis
  systemctl start mariadb
  systemctl start redis

  # SELinux (allow nginx and redis)
  setsebool -P httpd_can_network_connect 1
  setsebool -P httpd_execmem 1
  setsebool -P httpd_unified 1

  echo "* Dependencies for CentOS installed!"
}

#################################
## OTHER OS SPECIFIC FUNCTIONS ##
#################################

function ubuntu_universedep {
  # Probably should change this, this is more of a bandaid fix for this
  # This function is ran before software-properties-common is installed
  apt update -y
  apt install software-properties-common -y

  if grep -q universe "$SOURCES_PATH"; then
    # even if it detects it as already existent, we'll still run the apt command to make sure
    add-apt-repository universe
    echo "* Ubuntu universe repo already exists."
  else
    add-apt-repository universe
  fi
}

function centos_php {
  curl -o /etc/php-fpm.d/www-pterodactyl.conf $CONFIGS_URL/www-pterodactyl.conf

  systemctl enable php-fpm
  systemctl start php-fpm
}

function firewall_ufw {
  apt install ufw -y

  echo -e "\n* Enabling Uncomplicated Firewall (UFW)"
  echo "* Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"
  
  # pointing to /dev/null silences the command output
  ufw allow ssh > /dev/null
  ufw allow http > /dev/null
  ufw allow https > /dev/null
  
  ufw enable
  ufw status numbered | sed '/v6/d'
}

function debian_based_letsencrypt {
  # Install certbot and setup the certificate using the FQDN
  apt install certbot -y

  systemctl stop nginx

  echo -e "\nMake sure you choose Option 1, and create a Standalone Web Server during the certificate"
  certbot certonly -d "$FQDN"

  systemctl restart nginx
}

#######################################
## WEBSERVER CONFIGURATION FUNCTIONS ##
#######################################

function configure_nginx {
  echo "* Configuring nginx .."

  if [ "$ASSUME_SSL" == true ]; then
    DL_FILE="nginx_ssl.conf"
  else
    DL_FILE="nginx.conf"
  fi

  if [ "$OS" == "centos" ]; then
      # remove default config
      rm -rf /etc/nginx/conf.d/default

      # download new config
      curl -o /etc/nginx/conf.d/pterodactyl.conf $CONFIGS_URL/$DL_FILE

      # replace all <domain> places with the correct domain
      sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/pterodactyl.conf

      # replace all <php_socket> places with correct socket "path"
      sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/conf.d/pterodactyl.conf
  else
      # remove default config
      rm -rf /etc/nginx/sites-enabled/default

      # download new config
      curl -o /etc/nginx/sites-available/pterodactyl.conf $CONFIGS_URL/$DL_FILE

      # replace all <domain> places with the correct domain
      sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-available/pterodactyl.conf

      # replace all <php_socket> places with correct socket "path"
      sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/sites-available/pterodactyl.conf

      # enable pterodactyl
      ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  fi

  # restart nginx
  systemctl restart nginx
  echo "* nginx configured!"
}

function configure_apache {
  echo "soon .."
}

###########
## OTHER ##
###########

function install_daemon {
  echo "* It is recommended to have the panel and daemon on two separate nodes."
  echo -n "* Would you like to also install the Pterodactyl daemon on this machine? (y/N): "
  read -r INSTALL_DAEMON

  if [[ "$INSTALL_DAEMON" =~ [Yy] ]]; then
    bash <(curl -s https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/install-daemon.sh)
  fi
}

####################
## MAIN FUNCTIONS ##
####################

function perform_install {
  echo "* Starting installation.. this might take a while!"
  # do different things depending on OS
  if [ "$OS" == "ubuntu" ]; then
    ubuntu_universedep
    apt_update
    # different dependencies depending on if it's 18 or 16
    if [ "$OS_VER_MAJOR" == "18" ]; then
      ubuntu18_dep
    elif [ "$OS_VER_MAJOR" == "16" ]; then
      ubuntu16_dep
    else
      print_error "Unsupported version of Ubuntu."
      exit 1
    fi
    install_composer
    ptdl_dl
    create_database
    configure
    insert_cronjob
    install_pteroq

    if [ "$OS_VER_MAJOR" == "18" ]; then
      if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
        debian_based_letsencrypt
      fi
    fi
  elif [ "$OS" == "zorin" ]; then
    ubuntu_universedep
    apt_update
    if [ "$OS_VER_MAJOR" == "15" ]; then
      ubuntu18_dep
    else
      print_error "Unsupported version of Zorin."
      exit 1
    fi
    install_composer
    ptdl_dl
    create_database
    configure
    insert_cronjob
    install_pteroq
  elif [ "$OS" == "debian" ]; then
    apt_update
    if [ "$OS_VER_MAJOR" == "8" ] || [ "$OS_VER_MAJOR" == "9" ]; then
      debian_jessie_dep
    elif [ "$OS_VER_MAJOR" == "10" ]; then
      debian_dep
    fi
    install_composer
    ptdl_dl
    create_database
    configure
    insert_cronjob
    install_pteroq

    if [ "$OS_VER_MAJOR" == "9" ] || [ "$OS_VER_MAJOR" == "10" ]; then
      if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
        debian_based_letsencrypt
      fi
    fi
  elif [ "$OS" == "centos" ]; then
    if [ "$OS_VER_MAJOR" == "7" ]; then
      centos7_dep
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      centos8_dep
    fi
    centos_php
    install_composer
    ptdl_dl
    create_database
    configure
    insert_cronjob
    install_pteroq
  else
    # exit
    print_error "OS not supported."
    exit 1
  fi

  # perform webserver configuration
  if [ "$WEBSERVER" == "nginx" ]; then
    configure_nginx
  elif [ "$WEBSERVER" == "apache" ]; then
    configure_apache
  else
    print_error "Invalid webserver."
    exit 1
  fi

  if [ "$CONFIGURE_UFW" == true ]; then
    firewall_ufw
  fi
}

function ask_letsencrypt {
  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=true
  fi
}

function main {
  # detect distro
  detect_distro

  print_brake 70
  echo "* Pterodactyl panel installation script"
  echo "*"
  echo "* Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al."
  echo "* https://github.com/VilhelmPrytz/pterodactyl-installer"
  echo "*"
  echo "* This script is not associated with the official Pterodactyl Project."
  echo "*"
  echo "* Running $OS version $OS_VER."
  print_brake 70

  # checks if the system is compatible with this installation script
  check_os_comp

  while [ "$WEBSERVER_INPUT" != "1" ]; do
    echo "* [1] - nginx"
    echo -e "\e[9m* [2] - apache\e[0m - \e[1mApache not supported yet\e[0m"

    echo ""

    echo -n "* Select webserver to install pterodactyl panel with: "
    read -r WEBSERVER_INPUT

    if [ "$WEBSERVER_INPUT" == "1" ]; then
      WEBSERVER="nginx"
    else
      # exit
      print_error "Invalid webserver."
    fi
  done

  # set database credentials
  print_brake 72
  echo "* Database configuration."
  echo ""
  echo "* This will be the credentials used for commuication between the MySQL"
  echo "* database and the panel. You do not need to create the database"
  echo "* before running this script, the script will do that for you."
  echo ""

  echo -n "* Database name (panel): "
  read -r MYSQL_DB_INPUT

  if [ -z "$MYSQL_DB_INPUT" ]; then
    MYSQL_DB="panel"
  else
    MYSQL_DB=$MYSQL_DB_INPUT
  fi

  echo -n "* Username (pterodactyl): "
  read -r MYSQL_USER_INPUT

  if [ -z "$MYSQL_USER_INPUT" ]; then
    MYSQL_USER="pterodactyl"
  else
    MYSQL_USER=$MYSQL_USER_INPUT
  fi

  # MySQL password input
  while [ -z "$MYSQL_PASSWORD" ]; do
    echo -n "* Password (use something strong): "

    # modified from https://stackoverflow.com/a/22940001
    while IFS= read -r -s -n1 char; do
      [[ -z $char ]] && { printf '\n'; break; } # ENTER pressed; output \n and break.
      if [[ $char == $'\x7f' ]]; then # backspace was pressed
          # Only if variable is not empty
          if [ -n "$MYSQL_PASSWORD" ]; then
            # Remove last char from output variable.
            [[ -n $MYSQL_PASSWORD ]] && MYSQL_PASSWORD=${MYSQL_PASSWORD%?}
            # Erase '*' to the left.
            printf '\b \b' 
          fi
      else
        # Add typed char to output variable.
        MYSQL_PASSWORD+=$char
        # Print '*' in its stead.
        printf '*'
      fi
    done

    if [ -z "$MYSQL_PASSWORD" ]; then
      print_error "MySQL password cannot be empty"
    fi
  done

  print_brake 72

  # set FQDN
  while [ -z "$FQDN" ]; do
      echo -n "* Set the FQDN of this panel (panel.example.com): "
      read -r FQDN

      if [ -z "$FQDN" ]; then
        print_error "FQDN cannot be empty"
      fi
  done
  
  # UFW is available for Ubuntu/Debian
  # Let's Encrypt, in this setup, is only available on Ubuntu/Debian
  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ]; then
    # Available for Debian 9/10
    if [ "$OS" == "debian" ]; then
      if [ "$OS_VER_MAJOR" == "9" ] || [ "$OS_VER_MAJOR" == "10" ]; then
        ask_letsencrypt
      fi
    fi

    # Available for Ubuntu 18
    if [ "$OS" == "ubuntu" ] && [ "$OS_VER_MAJOR" == "18" ]; then
      ask_letsencrypt
    fi

    echo -e -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
    read -r CONFIRM_UFW

    if [[ "$CONFIRM_UFW" =~ [Yy] ]]; then
      CONFIGURE_UFW=true
    fi
  fi

  # If it's already true, this should be a no-brainer
  if [ "$CONFIGURE_LETSENCRYPT" == false ]; then
    echo "* Let's Encrypt is not going to be automatically configured by this script (either unsupported yet or user opted out)."
    echo "* You can 'assume' Let's Encrypt, which means the script will download a nginx configuration that is configured to use a Let's Encrypt certificate but the script won't obtain the certificate for you."
    echo "* If you assume SSL and do not obtain the certificate, your installation will not work."

    echo -n "* Assume SSL or not? (y/N): "
    read -r ASSUME_SSL_INPUT
    
    if [[ "$ASSUME_SSL_INPUT" =~ [Yy] ]]; then
      ASSUME_SSL=true
    fi
  fi

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

function goodbye {
  print_brake 62
  echo "* Pterodactyl Panel successfully installed @ $FQDN"
  echo "* "
  echo "* Installation is using $WEBSERVER on $OS"
  echo "* Thank you for using this script."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you haven't configured the firewall: 80/443 (HTTP/HTTPS) is required to be open!"
  print_brake 62
  install_daemon
}

# run script
main
goodbye
