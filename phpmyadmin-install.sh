#!/bin/bash

#### Install PhpMyAdmin ####
PHPMYADMIN=5.1.1
DIR=/var/www/pterodactyl

if [ -d "$DIR" ]; then
echo "The default directory exists, proceeding with the installation..."
cd /var/www/pterodactyl/public
mkdir -p phpmyadmin
cd phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN}/phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
tar -xzvf phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
cd phpMyAdmin-${PHPMYADMIN}-all-languages
cp -R * /var/www/pterodactyl/public/phpmyadmin
cd ..
rm -R phpMyAdmin-${PHPMYADMIN}-all-languages phpMyAdmin-${PHPMYADMIN}-all-languages.tar.gz
cp config.sample.inc.php config.inc.php
rm -R config.sample.inc.php
cd /var/www/pterodactyl/public/phpmyadmin || exit
echo "Thanks for using this script, goodbye."
else
echo "Default directory does not exist, aborting!"
fi

#### Updating Repositories ####

apt-get -y update
apt-get -y upgrade

#### Default MySQL credentials ####

MYSQL_USER="admin"
MYSQL_PASS="phpmyadminuser2021"

#### Create MySQL User ####

echo "Let's create a login user on the phpMyAdmin page."
echo
echo -n "* Username (default > admin): "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSQL_USER_INPUT

echo
echo -n "* Password (default > phpmyadminuser2021)"
read -r MYSQL_PASS_INPUT
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASS="phpmyadminuser2021" || MYSQL_PASS=$MYSQL_PASS_INPUT
echo "**************************************************"

#### Database ####

echo "* Creating user..."
mysql -u root -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';"

echo "* Creating database..."
mysql -u root -e "CREATE DATABASE phpmyadmin;"

echo "* Grant privileges..."
mysql -u root -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;"

echo "* Flush privileges..."
mysql -u root -e "FLUSH PRIVILEGES;"

#### Restart MySQL Service ####

systemctl restart mysql

echo "* MySQL user created and configured successfully!"
echo "**************************************************"
