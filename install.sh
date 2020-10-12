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

output() {
  echo "* ${1}"
}

error() {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

panel=false
wings=false

output "Pterodactyl installation script"
output
output "Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al."
output "https://github.com/vilhelmprytz/pterodactyl-installer"
output
output "Sponsoring/Donations: https://github.com/vilhelmprytz/pterodactyl-installer?sponsor=1"
output "This script is not associated with the official Pterodactyl Project."

output

while [ "$panel" == false ] && [ "$wings" == false ]; do
  output "What would you like to do?"
  output "[1] Install the panel"
  output "[2] Install the daemon (Wings)"
  output "[3] Install both on the same machine"

  echo -n "* Input 1-3: "
  read -r action

  case $action in
      1 )
          panel=true ;;
      2 )
          wings=true ;;
      3 )
          panel=true
          wings=true ;;
      * )
          error "Invalid option" ;;
  esac
done

[ "$panel" == true ] && bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-panel.sh)
[ "$wings" == true ] && bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-wings.sh)
