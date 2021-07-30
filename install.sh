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

SCRIPT_VERSION="v0.7.0"

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
  echo -e "* ${1}"
}

error() {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

done=false

output "Pterodactyl installation script @ $SCRIPT_VERSION"
output
output "Copyright (C) 2018 - 2021, Vilhelm Prytz, <vilhelm@prytznet.se>"
output "https://github.com/vilhelmprytz/pterodactyl-installer"
output
output "Sponsoring/Donations: https://github.com/vilhelmprytz/pterodactyl-installer?sponsor=1"
output "This script is not associated with the official Pterodactyl Project."

output

panel() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/$SCRIPT_VERSION/install-panel.sh)
}

wings() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/$SCRIPT_VERSION/install-wings.sh)
}

legacy_panel() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/$SCRIPT_VERSION/legacy/panel_0.7.sh)
}

legacy_wings() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/$SCRIPT_VERSION/legacy/daemon_0.6.sh)
}

canary_panel() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-panel.sh)
}

canary_wings() {
  bash <(curl -s https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/install-wings.sh)
}

while [ "$done" == false ]; do
  options=(
    "Install the panel"
    "Install Wings"
    "Install both [0] and [1] on the same machine (wings script runs after panel)\n"

    "Install 0.7 version of panel (unsupported, no longer maintained!)"
    "Install 0.6 version of daemon (works with panel 0.7, no longer maintained!)"
    "Install both [3] and [4] on the same machine (daemon script runs after panel)\n"

    "Install panel with canary version of the script (the versions that lives in master, may be broken!)"
    "Install Wings with canary version of the script (the versions that lives in master, may be broken!)"
    "Install both [5] and [6] on the same machine (wings script runs after panel)"
  )

  actions=(
    "panel"
    "wings"
    "panel; wings"

    "legacy_panel"
    "legacy_wings"
    "legacy_panel; legacy_wings"

    "canary_panel"
    "canary_wings"
    "canary_panel; canary_wings"
  )

  output "What would you like to do?"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* Input 0-$((${#actions[@]}-1)): "
  read -r action

  [ -z "$action" ] && error "Input is required" && continue

  valid_input=("$(for ((i=0;i<=${#actions[@]}-1;i+=1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Invalid option"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && eval "${actions[$action]}"
done
