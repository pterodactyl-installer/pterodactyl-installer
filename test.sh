#!bin/bash

#### Updating Repositories ####
update_repositories() {
apt-get -y update
apt-get -y upgrade
}

#### Default MySQL credentials ####
MYSQL_USER="admin"
MYSQL_PASSWORD=""

#### Create MySQL User ####

main() {
echo "Let's create a login user on the phpMyAdmin page."
echo
echo -n "* Username (admin): "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSEL_USER_INPUT
rand_pw=$(
    tr -dc 'A-Za-z0-9!"#$%&()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 64
    echo
	)
password_input MYSQL_PASSWORD "Password (press enter to use randomly generated password): " "MySQL password cannot be empty" "$rand_pw"

#### Database ####

echo "* Creating user..."
mysql -u root -p -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

echo "* Creating database..."
mysql -u root -p -e "CREATE DATABASE phpmyadmin;"

echo "* Grant privileges..."
mysql -u root -p -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;"

echo "* Flush privileges..."
mysql -u root -p -e "FLUSH PRIVILEGES;"

echo "* MySQL user created and configured successfully!"
}
