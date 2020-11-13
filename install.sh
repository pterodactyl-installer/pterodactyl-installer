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

done=false

output "Pterodactyl installation script"
output
output "Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al."
output "https://github.com/vilhelmprytz/pterodactyl-installer"
output
output "Sponsoring/Donations: https://github.com/vilhelmprytz/pterodactyl-installer?sponsor=1"
output "This script is not associated with the official Pterodactyl Project."

output

panel() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-panel.sh)
}

wings() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-wings.sh)
}

legacy_panel() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/legacy/panel_0.7.sh)
}

legacy_wings() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/legacy/daemon_0.6.sh)
}

while [ "$done" == false ]; do
  done=true

  output "What would you like to do?"
  output "[1] Install the panel"
  output "[2] Install the daemon (Wings)"
  output "[3] Install both on the same machine, i.e. [1] and [2]"
  output "[4] Install 0.7 version of panel (no longer maintained)"
  output "[5] Install 0.6 version of daemon (works with panel 0.7, no longer maintained)"
  output "[6] Install both [4] and [5] on the same machine (daemon script runs after panel)"

  echo -n "* Input 1-6: "
  read -r action

  case $action in
      1 )
          panel ;;
      2 )
          wings ;;
      3 )
          panel
          wings ;;
      4 )
          legacy_panel ;;
      5 )
          legacy_wings ;;
      6 )
          legacy_panel
          legacy_wings ;;          
      * )
          error "Invalid option"
          done=false ;;
  esac
done
