#!/bin/bash

set -e

#### check root privileges ####

if [[ $EUID -ne 0 ]]; then
echo "*You need to have root privileges for execue that (sudo)." 1>&2
exit 1
fi


#### Colors ####

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
reset="\e[0m"
red='\033[0;31m'

#### Check Distro ####

check_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID")
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID")
    OS_VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS="debian"
    OS_VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    OS="SuSE"
    OS_VER="?"
  elif [ -f /etc/redhat-release ]; then
    OS="Red Hat/CentOS"
    OS_VER="?"
  else
    OS=$(uname -s)
    OS_VER=$(uname -r)
  fi

  OS=$(echo "$OS")
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

#### Exec Check Distro ####
check_distro


#### Update Repositories ####

case "$OS" in
debian | ubuntu)
apt-get -y update
apt-get -y upgrade
;;
centos)
[ "$OS_VER_MAJOR" == "7" ] && yum -y update && yum -y upgrade
[ "$OS_VER_MAJOR" == "8" ] && dnf -y update && dnf -y upgrade
;;
esac

#### Install Dependecies ####

case "$OS" in
centos)
[ "$OS_VER_MAJOR" == "7" ] && yum -y install curl && yum -y install wget
[ "$OS_VER_MAJOR" == "8" ] && dnf -y install curl && dnf -y install wget
;;
esac


#### Variables ####

GITHUB_SOURCE="master"
GITHUB_BASE_URL="https://raw.githubusercontent.com/Ferks-FK/pterodactyl-installer/$GITHUB_SOURCE"


#### Install PhpMyAdmin for Debian and Ubuntu ####


PHPMYADMIN=5.1.1
DIR=/var/www/pterodactyl
case "$OS" in
debian | ubuntu)
if [ -d "$DIR" ]; then
echo "********************************************************************"
echo "* The default directory exists, proceeding with the installation...*"
echo "********************************************************************"
cd /var/www/pterodactyl/public
mkdir -p phpmyadmin && chown www-data.www-data /var/www/pterodactyl/public/phpmyadmin -R
cd phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN}/phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
tar -xzvf phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
cd phpMyAdmin-${PHPMYADMIN}-all-languages
cp -R -- * /var/www/pterodactyl/public/phpmyadmin
cd ..
rm -R phpMyAdmin-${PHPMYADMIN}-all-languages phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz config.sample.inc.php
curl -o /var/www/pterodactyl/public/phpmyadmin/config.inc.php $GITHUB_BASE_URL/configs/config.inc.php
mkdir -p tmp && chmod 777 tmp -R
cd
mkdir -p /etc/phpmyadmin && chown www-data.www-data /etc/phpmyadmin -R && chmod 660 /etc/phpmyadmin -R
cd /etc/phpmyadmin
mkdir -p tmp upload save
else
echo "***************************************************************"
echo "* You don't have the panel installed, please install it first!*"
echo "***************************************************************"
exit 1
fi
;;
esac


#### Install PhpMyAdmin for CentOS ####

case "$OS" in
centos)
[ "OS_VER_MAJOR" == "7" ]
if [ -d "$DIR" ]; then
echo "********************************************************************"
echo "* The default directory exists, proceeding with the installation...*"
echo "********************************************************************"
cd /var/www/pterodactyl/public
mkdir -p phpmyadmin && chown nginx:nginx /var/www/pterodactyl/public/phpmyadmin -R
cd phpmyadmin
tar -xzvf phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
cd phpMyAdmin-${PHPMYADMIN}-all-languages
cp -R -- * /var/www/pterodactyl/public/phpmyadmin
cd ..
rm -R phpMyAdmin-${PHPMYADMIN}-all-languages phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz config.sample.inc.php
curl -o /var/www/pterodactyl/public/phpmyadmin/config.inc.php $GITHUB_BASE_URL/configs/config.inc.php
mkdir -p tmp && chmod 777 tmp -R
cd
mkdir -p /etc/phpmyadmin && chown nginx:nginx /etc/phpmyadmin -R && chmod 660 /etc/phpmyadmin -R
cd /etc/phpmyadmin
mkdir -p tmp upload save
else
echo "***************************************************************"
echo "* You don't have the panel installed, please install it first!*"
echo "***************************************************************"
exit 1
fi
;;
esac


case "$OS" in
centos)
[ "OS_VER_MAJOR" == "8" ]
if [ -d "$DIR" ]; then
echo "********************************************************************"
echo "* The default directory exists, proceeding with the installation...*"
echo "********************************************************************"
cd /var/www/pterodactyl/public
mkdir -p phpmyadmin && chown nginx:nginx /var/www/pterodactyl/public/phpmyadmin -R
cd phpmyadmin
tar -xzvf phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
cd phpMyAdmin-${PHPMYADMIN}-all-languages
cp -R -- * /var/www/pterodactyl/public/phpmyadmin
cd ..
rm -R phpMyAdmin-${PHPMYADMIN}-all-languages phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz config.sample.inc.php
curl -o /var/www/pterodactyl/public/phpmyadmin/config.inc.php $GITHUB_BASE_URL/configs/config.inc.php
mkdir -p tmp && chmod 777 tmp -R
cd
mkdir -p /etc/phpmyadmin && chown nginx:nginx /etc/phpmyadmin -R && chmod 660 /etc/phpmyadmin -R
cd /etc/phpmyadmin
mkdir -p tmp upload save
else
echo "***************************************************************"
echo "* You don't have the panel installed, please install it first!*"
echo "***************************************************************"
exit 1
fi
;;
esac

#### Default MySQL credentials ####

MYSQL_USER="admin"
MYSQL_PASS="phpmyadminuser2021"

#### Create MySQL User ####

echo
echo "****************************************************"
echo "* Let's create a login user on the phpMyAdmin page.*"
echo "****************************************************"
echo
echo -e "* ${GREEN}Username ${YELLOW}(admin)${reset}: "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSQL_USER_INPUT

echo
echo -n "* ${GREEN}Database name ${YELLOW}(phpmyadmin)${reset}: "
read -r MYSQL_DATABASE_INPUT
[ -z "$MYSQL_DATABASE_INPUT" ] && MYSQL_DATABASE="phpmyadmin" || MYSQL_DATABASE=$MYSQL_DATABASE_INPUT

echo
echo -n "* ${GREEN}Password ${YELLOW}(phpmyadminuser2021)${reset}: "
read -s MYSQL_PASS_INPUT
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASS="phpmyadminuser2021" || MYSQL_PASS=$MYSQL_PASS_INPUT
echo
echo

#### Review of settings ####

summary() {
echo "******************************"
echo "* Username: $MYSQL_USER"
echo "* Database name: $MYSQL_DATABASE"
echo "* Password: (censored)"
echo "******************************"
}


#### Exec summary ####
summary


continue_install() {
echo "**************************************************"

#### Database ####

echo "* Creating user..."
mysql -u root -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';"

echo "* Creating database..."
mysql -u root -e "CREATE DATABASE ${MYSQL_DATABASE};"

echo "* Grant privileges..."
mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;"

echo "* Flush privileges..."
mysql -u root -e "FLUSH PRIVILEGES;"

#### Restart MySQL Service ####

echo "* Restarting MySQL..."
systemctl restart mysql

echo "* MySQL user created and configured successfully!"
echo
echo "**************************************************"
}

#### Exec Install ####

echo -e -n "\n* Initial configuration completed. Continue with installation? (y/N): "
read -r CONFIRM
if [[ "$CONFIRM" =~ [Yy] ]]; then
    continue_install
  else
    echo "Installation aborted!"
    exit 1
fi

#### Last care ####

echo
echo 
echo "*************************** ATTENTION ***************************"
echo
echo "Let's make the last changes to the phpMyAdmin configuration file."
echo
echo
echo
echo "First, let's generate a security key, leave it to me :)"
echo
echo "Generating a safe word..."
sleep 4
echo
echo "Here it is:"
echo "*********************************************"
openssl rand -base64 32
echo "*********************************************"
echo
echo
echo "Run this command: nano /var/www/pterodactyl/public/phpmyadmin/config.inc.php"
echo "and on line 16, replace 'YOUR-SECRET-WORD-HERE!' By your generated key."
echo
echo "Also save your username and password you chose at installation, and on lines 19 and 20, the correct data."
echo
echo
echo "Thanks for using this script, goodbye."
