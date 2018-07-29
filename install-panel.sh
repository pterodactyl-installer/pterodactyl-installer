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

# main functions
function install_composer {
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
}

function ptdl_dl {
  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl

  curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.9/panel.tar.gz
  tar --strip-components=1 -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/

  cp .env.example .env
  composer install --no-dev --optimize-autoloader

  php artisan key:generate --force
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

# OS specific functions
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

###########################
## PRE INSTALL QUESTIONS ##
###########################
