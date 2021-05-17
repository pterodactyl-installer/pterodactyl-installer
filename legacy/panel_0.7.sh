#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer'                                           #
#                                                                           #
# Copyright (C) 2018 - 2021, Vilhelm Prytz, <vilhelm@prytznet.se>           #
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

SCRIPT_PATH="/tmp/panel_install_0.7.sh"

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
  curl -o "$SCRIPT_PATH" https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/b8e298003fe3120edccb02fabc5d7e86daef22e6/install-panel.sh
  chmod +x "$SCRIPT_PATH"
}

replace() {
  sed -i 's/master/b8e298003fe3120edccb02fabc5d7e86daef22e6/g' "$SCRIPT_PATH"
  sed -i '/PTERODACTYL_VERSION=/c\PTERODACTYL_VERSION="v0.7.19"' "$SCRIPT_PATH"
  sed -i 's*https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz*https://github.com/pterodactyl/panel/releases/download/v0.7.19/panel.tar.gz*g' "$SCRIPT_PATH"

  # an older version of composer is required for 0.7
  sed -i 's/--filename=composer/--filename=composer --version=1.10.22/g' "$SCRIPT_PATH"
}

main() {
  dl_script
  replace
  bash "$SCRIPT_PATH"
}

main
