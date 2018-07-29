#!/bin/bash
# pterodactyl-installer panel
# Copyright Vilhelm Prytz 2018
# https://github.com/mrkakisen/pterodactyl-installer

# check if user is root or not
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

# variables
WEBSERVER="nginx"
OS="debian" # can
FQDN="pterodactyl.panel"

# visual functions
function print_error {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo -e "* ${COLOR_RED}error${COLOR_NC}: $1"
}

# other functions
function detect_distro {
  OS="$(python -c 'import platform ; print platform.dist()[0]')" | awk '{print tolower($0)}'
}

# main installation functions
function install_composer {
  echo "* Installing composer.."
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
  echo "* Composer installed!"
}

function ptdl_dl {
  echo "* Downloading pterodactyl panel files .. "
  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl

  curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.9/panel.tar.gz
  tar --strip-components=1 -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/

  cp .env.example .env
  composer install --no-dev --optimize-autoloader

  php artisan key:generate --force
  echo "* Downloaed pterodactyl panel files & installed composer dependencies!"
}

function configure {
  echo "* Please follow the steps below. The installer will ask you for configuration details."
  php artisan p:environment:setup

  echo "* The installer will now ask you for MySQL database credentials."
  php artisan p:environment:database

  echo "* The installer will now ask you for mail setup / mail credentials."
  php artisan p:environment:mail

  # configures database
  php artisan migrate --seed

  echo "* The installer will now ask you to create the inital admin user account."
  php artisan p:user:make

  # set folder permissions now
  set_folder_permissions
}

# set the correct folder permissions depending on OS and webserver
function set_folder_permissions {
  # if os is ubuntu or debian, we do this
  if ["$OS" == "debian" ] || ["$OS" == "ubuntu" ]; then
    chown -R www-data:www-data *
  elif ["$OS" == "centos"] && ["$WEBSERVER" == "nginx" ]; then
    chown -R nginx:nginx *
  elif ["$OS" == "centos"] && ["$WEBSERVER" == "apache" ]; then
    chown -R apache:apache *
  else
    print_error Invalid webserver and OS setup.
    exit 1
  fi
}

# insert cronjob
function insert_cronjob {
  echo "* Installing cronjob.. "

  # removed alternate method
  #crontab -l > mycron
  #echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" >> mycron
  #crontab mycron
  #rm mycron
  crontab -l | { cat; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"; } | crontab -

  echo "* Cronjob installed!"
}

function install_pteroq {
  echo "* Installing pteroq service.."

  curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/MrKaKisen/pterodactyl-installer/master/configs/pteroq.service
  systemctl enable pteroq.service
  systemctl start pteroq

  echo "* Installed pteroq!"
}

# OS specific install functions
function apt_update {
  apt update -y && apt upgrade -y
}

function ubuntu_dep {
  echo "* Installing dependencies for Ubuntu.."

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

  echo "* Dependencies for Ubuntu installed!"
}


function debian_dep {
  echo "* Installing dependencies for Debian.."

  # install PHP 7.2 using Sury's rep instead of PPA
  # this guide shows how: https://wiki.mrkakisen.net/index.php?title=Installing_PHP_7.2_on_Debian_8_and_9
  apt install ca-certificates apt-transport-https lsb-release -y
  sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

  # redis-server is not installed using the PPA, as it's already available in the Debian repo

  # Install MariaDb
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # Update repositories list
  apt update

  # Install Dependencies
  apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx curl tar unzip git redis-server

  echo "* Dependencies for Debian installed!"
}

function centos_dep {
  echo "* Installing dependencies for CentOS.."

  # update first
  yum update -y

  # install php7.2
  yum -y install epel-release
  yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
  yum -y install yum-utils
  yum-config-manager --enable remi-php72
  yum update -y

  # Install MariaDB
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  # install dependencies
  yum -y install install php72 php72-cli php72-gd php72-mysql php72-pdo php72-mbstring php72-tokenizer php72-bcmath php72-xml php72-fpm php72-curl php72-zip mariadb-server nginx curl tar unzip git redis

  # enable services
  systemctl start redis
  systemctl enable redis
  systemctl enable php72-php-fpm.service
  sudo systemctl start php72-php-fpm.service

  echo "* Dependencies for CentOS installed!"
}

####################
## MAIN FUNCTIONS ##
####################

function perform_install {
  # do different things depending on OS
  if ["$OS" == "ubuntu" ]; then
    apt_update
    ubuntu_dep
    install_composer
    ptdl_dl
    configure
    insert_cronjob
    install_pteroq
  elif ["$OS" == "debian" ]; then
    apt_update
    debian_dep
    install_composer
    ptdl_dl
    configure
    insert_cronjob
    install_pteroq
  elif ["$OS" == "centos" ]; then
    # coming soon
    print_error CentOS support is coming soon.
    exit 1
  else
    # run welcome script again
    print_error OS not supported.
    exit 1
  fi
}

function main {
  echo "########################################"
  echo "* Pterodactyl panel installation script "
  echo "* Detecting operating system."
  detect_distro
  echo "* Running $OS."
  echo "#########################################"
  echo "* [1] - nginx"
  echo -e "\e[9m* [2] - apache\e[0m - \e[1mApache not supported yet\e[0m"

  echo -n "* Select webserver to install pterodactyl panel with: "
  read WEBSERVER_INPUT

  if ["$WEBSERVER_INPUT" == "1" ]; then
    WEBSERVER="nginx"
  else
    # run welcome script again
    print_error Invalid webserver.
    welcome
  fi

  # confgirm installation
  echo -e -n "\n* Inital configuration done. Do you wan't to continue with installation? (y/n): "
  read CONFIRM
  if ["$CONFIRM" == "y" ]; then
    perform_install
  elif ["$CONFIRM" == "n" ]; then
    exit 0
  else
    # run welcome script again
    print_error Invalid confirm. Will exit.
    exit 1
  fi

}


# start main function
main()
