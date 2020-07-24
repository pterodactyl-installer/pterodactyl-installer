#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for master                                #
#                                                                           #
# Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al.   #
#                                                                           #
#   This program is free software: you can redistribute it and/or modify    #
#   it under the terms of the GNU General Public License as published by    #
#   the Free Software Foundation, either version 3 of the License, or       #
#   (at your option) any later version.                                     #
#                                                                           #
#   This program is distributed in the hope that it will be useful,         #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of          #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
#   GNU General Public License for more details.                            #
#                                                                           #
#   You should have received a copy of the GNU General Public License       #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.  #
#                                                                           #
# https://github.com/vilhelmprytz/pterodactyl-installer/blob/master/LICENSE #
#                                                                           #
# This script is not associated with the official Pterodactyl Project.      #
# https://github.com/vilhelmprytz/pterodactyl-installer                     #
#                                                                           #
#############################################################################

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

beta=false
daemon=false

echo "* " # @Prytz fill in question if beta version is needed

read -r install_beta

echo "* " # @Prytz fill in question if daemon (wings) is needed

read -r install_daemon

if [[ "$install_beta" =~ [Yy] ]]; then
    beta=true
fi

if [[ "$install_daemon" =~ [Yy] ]]; then
    daemon=true
fi

if "$beta"; then
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/pterodactyl-1.0/install-panel.sh)
  if "$daemon"; then
    bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/pterodactyl-1.0/install-wings.sh)
  fi
fi

if [ "$beta" == false ]; then
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-panel.sh)
  if "$daemon"; then
      bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-daemon.sh)
  fi
fi