#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer', upgrade panel 0.7 to 1.0                 #
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

php_version=""

OS=""
OS_VER=""
OS_VER_MAJOR=""

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

detect_distro() {
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si | awk '{print tolower($0)}')
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID" | awk '{print tolower($0)}')
    OS_VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS="debian"
    OS_VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS="SuSE"
    OS_VER="?"
  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS="Red Hat/CentOS"
    OS_VER="?"
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    OS_VER=$(uname -r)
  fi

  OS=$(echo "$OS" | awk '{print tolower($0)}')
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

# main functionality
root_check() {
  # exit with error status code if user is not root
  if [[ $EUID -ne 0 ]]; then
    echo "* This script must be executed with root privileges (sudo)." 1>&2
    exit 1
  fi
}

gather_environment() {
  _raw=$(php -v)
  php_version=${_raw:4:3}
  detect_distro
}

maintenance() {
  cd /var/www/pterodactyl && php artisan down
  # php-fpm is service name on CentOS, php version included on other distros
  systemctl stop php-fpm || systemctl stop php"$php_version"-fpm
}

upgrade_php() {
  [ "$OS" == "ubuntu" ] && apt-get purge -y 'php*'
  # fixme: finish this
}

# main
main() {
  root_check
  gather_environment
  maintenance
  [ "$php_version" != "7.4" ] && upgrade_php
  # fixme: finish this
}

main
