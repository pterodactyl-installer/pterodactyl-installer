#!/bin/bash

#### Panel Production ####

DIR=/var/www/pterodactyl

if [ -d "$DIR" ]; then
echo
echo "*******************************************************************"
echo "* The default directory exists, proceeding with the installation..."
echo "*******************************************************************"
echo
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - && apt-get install -y nodejs
cd /var/www/pterodactyl
npm i -g yarn
yarn
yarn build:production
else
echo
echo "***************************************************************"
echo "* You don't have the panel installed, please install it first!*"
echo "***************************************************************"
echo
fi
