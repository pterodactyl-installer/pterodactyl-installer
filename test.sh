#!/bin/bash

#### Variables ####
GITHUB_SOURCE="master"
GITHUB_BASE_URL="https://raw.githubusercontent.com/Ferks-FK/pterodactyl-installer/$GITHUB_SOURCE"

#### Install PhpMyAdmin ####
PHPMYADMIN=5.1.1
DIR=/var/www/pterodactyl

if [ -d "$DIR" ]; then
echo "********************************************************************"
echo "* The default directory exists, proceeding with the installation...*"
echo "********************************************************************"
cd /var/www/pterodactyl/public || exit
mkdir -p phpmyadmin && chown www-data.www-data /var/www/pterodactyl/public/phpmyadmin -R
cd phpmyadmin || exit
wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN}/phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
tar -xzvf phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
cd phpMyAdmin-${PHPMYADMIN}-all-languages || exit
cp -R -- * /var/www/pterodactyl/public/phpmyadmin
cd .. || exit
rm -R phpMyAdmin-${PHPMYADMIN}-all-languages phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz config.sample.inc.php
#### test ####
curl -o /var/www/pterodactyl/public/phpmyadmin/config.inc.php $GITHUB_BASE_URL/configs/config.inc.php
sed -i -e "s@<secret-word>@YOUR-SECRET-WORD-HERE!@g" /var/www/pterodactyl/public/phpmyadmin/config.inc.php
sed -i -e "s@<db-user>@${MYSQL_USER}@g" /var/www/pterodactyl/public/phpmyadmin/config.inc.php
sed -i -e "s@<db-pass>@${MYSQL_PASS}@g" /var/www/pterodactyl/public/phpmyadmin/config.inc.php
cd /var/www/pterodactyl/public/phpmyadmin || exit
mkdir -p tmp && chmod 777 tmp -R
cd || exit
mkdir -p /etc/phpmyadmin && chown www-data.www-data /etc/phpmyadmin -R && chmod 660 /etc/phpmyadmin -R
cd /etc/phpmyadmin || exit
mkdir -p tmp upload save
else
echo "***************************************************************"
echo "* You don't have the panel installed, please install it first!*"
echo "***************************************************************"
exit 1
fi

#### Updating Repositories ####

apt-get -y update
apt-get -y upgrade

#### Default MySQL credentials ####

MYSQL_USER="admin"
MYSQL_PASS="phpmyadminuser2021"

#### Create MySQL User ####
echo
echo "****************************************************"
echo "* Let's create a login user on the phpMyAdmin page.*"
echo "****************************************************"
echo
echo -n "* Username (admin): "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSQL_USER_INPUT

echo
echo -n "* Database name (phpmyadmin): "
read -r MYSQL_DATABASE_INPUT
[ -z "$MYSQL_DATABASE_INPUT" ] && MYSQL_DATABASE="phpmyadmin" || MYSQL_DATABASE=$MYSQL_DATABASE_INPUT

echo
echo -n "* Password (phpmyadminuser2021): "
read -r MYSQL_PASS_INPUT
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASS="phpmyadminuser2021" || MYSQL_PASS=$MYSQL_PASS_INPUT
echo
echo

#### Review of settings ####

summary() {
echo "******************************"
echo "* Username: $MYSQL_USER"
echo "* Database name: $MYSQL_DATABASE"
echo "* Password: $MYSQL_PASS"
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
echo "* Thanks for using this script, goodbye."
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
