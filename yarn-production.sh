#!/bin/bash

#### Panel Production ####

DIR=/var/www/pterodactyl/efgewrgwergwergwergweg

if [ -d "$DIR" ]; then
echo "The default directory exists, proceeding with the installation..."
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - && apt-get install -y nodejs
cd /var/www/pterodactyl
npm i -g yarn
yarn
yarn build:production
else
echo "Default directory does not exist, aborting!"
fi
