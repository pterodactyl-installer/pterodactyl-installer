#!/bin/bash

#### Install PhpMyAdmin ####
PHPMYADMIN=5.1.1
DIR=/var/www/pterodactyl

install_phpmyadmin() {
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
else
echo "Default directory does not exist, aborting!"
fi
}
