#!/bin/bash

set -e

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for panel                                 #
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

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

# main functionality
install_wings() {
    mkdir -p /etc/pterodactyl
    curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    chmod u+x /usr/local/bin/wings
}

remove_daemon() {
    systemctl stop wings
    rm -rf /srv/daemon
}

remove_standalone_sftp() {
    # stop and disable the standalone sftp
    systemctl disable --now pterosftp

    # delete the systemd service
    rm -rf /etc/systemd/system/pterosftp.service
}

new_systemd() {
    curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/configs/wings.service
    systemctl daemon-reload
    systemctl enable wings
}

main() {
    echo "* Installing Wings and removing old daemon"

    install_wings
    remove_daemon
    remove_standalone_sftp
    new_systemd

    echo "* Completed. Please install the new configuration file before continuing."
    echo "* See: $(hyperlink 'https://pterodactyl.io/wings/1.0/migrating.html#copy-new-configuration-file')"
    echo "* Then start the daemon using"
    echo "* systemctl start wings"
}

main
