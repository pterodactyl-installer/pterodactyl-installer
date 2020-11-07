#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer'                                           #
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

SCRIPT_PATH="/tmp/daemon_install_0.7.sh"

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

dl_script() {
    rm -rf "$SCRIPT_PATH"
    curl -o "$SCRIPT_PATH" https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/b8e298003fe3120edccb02fabc5d7e86daef22e6/install-daemon.sh
    chmod +x "$SCRIPT_PATH"
}

replace() {
    sed -i 's/master/b8e298003fe3120edccb02fabc5d7e86daef22e6/g' "$SCRIPT_PATH"
    sed -i '/VERSION=/c\VERSION="v0.6.13"' "$SCRIPT_PATH"
    sed -i 's*https://github.com/pterodactyl/daemon/releases/latest/download/daemon.tar.gz*https://github.com/pterodactyl/daemon/releases/download/v0.6.13/daemon.tar.gz*g' "$SCRIPT_PATH"
}

main() {
    dl_script
    replace
    bash "$SCRIPT_PATH"
}

main
