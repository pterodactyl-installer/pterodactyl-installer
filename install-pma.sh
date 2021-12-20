#!/bin/bash

set -e


#### General checks ####

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


#### Variables ####

SCRIPT_VERSION="v0.9.1"
PMA_VERSION="5.1.1"
FQDN=""

#### Directory for installing PMA ####

DEFAULT_DIR="/var/www/phpmyadmin"

#### Default MySQL credentials ####

MYSQL_DB="phpmyadmin"
MYSQL_USER="admin"
MYSQL_PASSWORD=""


#### download URL

PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/$PMA_VERSION/phpMyAdmin-$PMA_VERSION-all-languages.tar.gz"

#### Visual functions ####


#### Colors ####

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
red='\033[0;31m'
reset="\e[0m"

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

#### OS check funtions ####

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

#### Create all necessary folders ####

create_folders() {
mkdir -p /etc/phpmyadmin/upload
mkdir -p /etc/phpmyadmin/save
mkdir -p /etc/phpmyadmin/tmp
mkdir -p /var/www/phpmyadmin/tmp
}

#### Define permisions ####

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
cd /var/www/phpmyadmin

curl -Lo phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz "$PMA_URL"
tar -xzvf phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PMA_VERSION}"-all-languages
mv -- * "$DEFAULT_DIR"
cd "$DEFAULT_DIR"
rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz && rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages && rm -r config.sample.inc.php
}


#### Create MySQL User ####
create_credentials() {
echo
print_brake 52
echo "* Let's create a login user on the phpMyAdmin page."
print_brake 52
echo
echo -n "* Username (${YELLOW}admin${reset}): "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSQL_USER_INPUT

echo
echo -n "* Password (${YELLOW}pmapassword${reset}): "
read -r MYSQL_PASS_INPUT
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASSWORD="pmapassword" || MYSQL_PASSWORD=$MYSQL_PASSWORD_INPUT
echo
if [ "$MYSQL_PASS_INPUT" == "pmapassword" ]; then
  print_warning "You are using the default password for PMA access, are you sure you want to continue with this password? (Y/N)"
  read -r UPDATE_MYSQL_PASS
    if [[ "$UPDATE_MYSQL_PASS" =~ [Yy] ]]; then
        echo
      else
        while [ -z "$MYSQL_PASS_INPUT" ]; do
          echo
          echo -n "* New Password: "
          read -r MYSQL_PASS_INPUT
          if [ "$MYSQL_PASS_INPUT" == "" ]; then
            print_error "Password cannot be empty!"
          fi
          [ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASSWORD="pmapassword" || MYSQL_PASSWORD=$MYSQL_PASS_INPUT
        done
    fi
fi
}

#### Create a databse with user ####

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


#### Exec Script ####

detect_distro
create_folders
define_permisions
pma_dl
create_database