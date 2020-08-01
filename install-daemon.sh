#!/bin/bash

#############################################################################
#                                                                           #
# Project 'pterodactyl-installer' for daemon                                #
#                                                                           #
# Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al.   #
#                                                                           #
# This script is licensed under the terms of the GNU GPL v3.0 license       #
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
CURLPATH="$(command -v curl)"
if [ -z "$CURLPATH" ]; then
    echo "* curl is required in order for this script to work."
    echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
    exit 1
fi

# define version using information from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

echo "* Retrieving release information.."
VERSION="$(get_latest_release "pterodactyl/daemon")"

echo "* Latest version is $VERSION"

# download URLs
DL_URL="https://github.com/pterodactyl/daemon/releases/latest/download/daemon.tar.gz"
CONFIGS_URL="https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/master/configs"

COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m'

INSTALL_STANDALONE_SFTP_SERVER=false
INSTALL_MARIADB=false

# visual functions
function print_error {
  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

function print_warning {
  COLOR_YELLOW='\033[1;33m'
  COLOR_NC='\033[0m'
  echo ""
  echo -e "* ${COLOR_YELLOW}WARNING${COLOR_NC}: $1"
  echo ""
}

function print_brake {
  for ((n=0;n<$1;n++));
    do
      echo -n "#"
    done
    echo ""
}


# other functions
function detect_distro {
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

function check_os_comp {
  MACHINE_TYPE=$(uname -m)
  if [ "${MACHINE_TYPE}" != "x86_64" ]; then # check the architecture
    print_warning "Detected architecture $MACHINE_TYPE"
    print_warning "Using any other architecture then 64 bit(x86_64) may (and will) cause problems."

    echo -e -n  "* Are you sure you want to proceed? (y/N):"
    read -r choice

    if [[ ! "$choice" =~ [Yy] ]]; then
      print_error "Installation aborted!"
      exit 1
    fi
  fi

  if [ "$OS" == "ubuntu" ]; then
    if [ "$OS_VER_MAJOR" == "16" ]; then
      SUPPORTED=true
    elif [ "$OS_VER_MAJOR" == "18" ]; then
      SUPPORTED=true
    elif [ "$OS_VER_MAJOR" == "20" ]; then
      SUPPORTED=true
    else
      SUPPORTED=false
    fi
  elif [ "$OS" == "zorin" ]; then
    if [ "$OS_VER_MAJOR" == "15" ]; then
      SUPPORTED=true
    else
      SUPPORTED=false
    fi
  elif [ "$OS" == "debian" ]; then
    if [ "$OS_VER_MAJOR" == "9" ]; then
      SUPPORTED=true
    elif [ "$OS_VER_MAJOR" == "10" ]; then
      SUPPORTED=true
    else
      SUPPORTED=false
    fi
  elif [ "$OS" == "centos" ]; then
    if [ "$OS_VER_MAJOR" == "7" ]; then
      SUPPORTED=true
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      SUPPORTED=true
    else
      SUPPORTED=false
    fi
  else
    SUPPORTED=false
  fi

  # exit if not supported
  if [ "$SUPPORTED" == true ]; then
    echo "* $OS $OS_VER is supported."
  else
    echo "* $OS $OS_VER is not supported"
    print_error "Unsupported OS"
    exit 1
  fi

  # check virtualization
  echo -e  "* Installing virt-what..."
  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ]; then
    apt-get -y update -qq > /dev/null

    # install virt-what
    apt-get install -y virt-what -qq > /dev/null

  elif [ "$OS" == "centos" ]; then
    if [ "$OS_VER_MAJOR" == "7" ]; then
      yum -q -y update

      # install virt-what
      yum -q -y install virt-what
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      dnf -y -q update

      # install virt-what
      dnf install -y -q virt-what
    fi
  else
    print_error "Invalid OS."
    exit 1
  fi

  virt_serv=$(virt-what)
  if [ "$virt_serv" != "" ]; then
    print_warning "Virtualization: ${virt_serv//$'\n'/ } detected."
  fi

  if [ "$virt_serv" == "openvz" ] || [ "$virt_serv" == "lxc" ] ; then # add more virtualization types which are not supported
    print_warning "Unsupported type of virtualization detected. Please consult with your hosting provider whether your server can run Docker or not. Proceed at your own risk."
    print_error "Installation aborted!"
    exit 1
  fi

  if uname -r | grep -q "xxxx"; then
    print_error "Unsupported kernel detected."
    exit 1
  fi
}

############################
## INSTALLATION FUNCTIONS ##
############################
function apt_update {
  apt update -y
  apt upgrade -y
}

function install_dep {
  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ]; then
    apt_update

    # install dependencies
    apt -y install tar unzip make gcc g++ python
  elif [ "$OS" == "centos" ]; then
    if [ "$OS_VER_MAJOR" == "7" ]; then
      yum -y update

      # install dependencies
      yum -y install tar unzip make gcc gcc-c++ python
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      dnf -y update

      # install dependencies
      dnf install -y tar unzip make gcc gcc-c++ python2

      alternatives --set python /usr/bin/python2
    fi
  else
    print_error "Invalid OS."
    exit 1
  fi
}
function install_docker {
  echo "* Installing docker .."
  if [ "$OS" == "debian" ]; then
    # install dependencies for Docker
    apt-get update
    apt-get -y install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common

    # get their GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

    # show fingerprint to user
    apt-key fingerprint 0EBFCD88

    # add APT repo
    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/debian \
      $(lsb_release -cs) \
      stable"

    # install docker
    apt-get update
    apt-get -y install docker-ce

    # make sure it's enabled & running
    systemctl start docker
    systemctl enable docker

  elif [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ]; then
    # install dependencies for Docker
    apt-get update
    apt-get -y install \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common

    # get their GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # show fingerprint to user
    apt-key fingerprint 0EBFCD88

    # add APT repo
    sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"

    # install docker
    apt-get update
    apt-get -y install docker-ce

    # make sure it's enabled & running
    systemctl start docker
    systemctl enable docker

  elif [ "$OS" == "centos" ]; then
    if [ "$OS_VER_MAJOR" == "7" ]; then
      # install dependencies for Docker
      yum install -y yum-utils device-mapper-persistent-data lvm2

      # add repo to yum
      yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

      # install Docker
      yum install -y docker-ce
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      # install dependencies for Docker
      dnf install -y dnf-utils device-mapper-persistent-data lvm2

      # add repo to dnf
      dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

      # install Docker
      dnf install -y docker-ce --nobest
    fi

    # make sure it's enabled & running
    systemctl start docker
    systemctl enable docker
  fi

  echo "* Docker has now been installed."
}

function install_nodejs {
  if [ "$OS" == "debian" ]; then
    curl -sL https://deb.nodesource.com/setup_10.x | bash -
    apt-get install -y nodejs
  elif [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ]; then
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
    apt -y install nodejs
  elif [ "$OS" == "centos" ]; then
    curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -

    if [ "$OS_VER_MAJOR" == "7" ]; then
      yum -y install nodejs
    elif [ "$OS_VER_MAJOR" == "8" ]; then
      dnf -y install nodejs
    fi
  fi
}

function ptdl_dl {
  echo "* Installing pterodactyl daemon .. "
  mkdir -p /srv/daemon /srv/daemon-data
  cd /srv/daemon || exit

  curl -L "$DL_URL" | tar --strip-components=1 -xzv
  npm install --only=production --unsafe-perm

  echo "* Done."
}

function systemd_file {
  echo "* Installing systemd service.."
  curl -o /etc/systemd/system/wings.service $CONFIGS_URL/wings.service
  systemctl daemon-reload
  systemctl enable wings
  echo "* Installed systemd service!"
}

function install_standalone_sftp_server {
  echo "* Installing standalone SFTP server.."

  INSTALL_PATH="/srv/daemon/sftp-server"

  curl -Lo $INSTALL_PATH https://github.com/pterodactyl/sftp-server/releases/download/v1.0.4/sftp-server
  chmod +x $INSTALL_PATH

  curl -o /etc/systemd/system/pterosftp.service $CONFIGS_URL/pterosftp.service

  systemctl daemon-reload
  systemctl enable pterosftp
}

function install_mariadb {
  if [ "$OS" == "ubuntu" ] || [ "$OS" == "zorin" ] || [ "$OS" == "debian" ]; then
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
    apt update && apt install mariadb-server -y
  elif [ "$OS" == "centos" ]; then
    [ "$OS_VER_MAJOR" == "7" ] && curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
    [ "$OS_VER_MAJOR" == "7" ] && yum -y install mariadb-server
    [ "$OS_VER_MAJOR" == "8" ] && dnf install -y mariadb mariadb-server
  else
    print_error "Unsupported OS for MariaDB installations!"
  fi
  systemctl enable mariadb
  systemctl start mariadb
}

####################
## MAIN FUNCTIONS ##
####################
function perform_install {
  echo "* Installing pterodactyl daemon.."

  install_dep
  install_docker
  install_nodejs
  ptdl_dl
  systemd_file
  [ "$INSTALL_STANDALONE_SFTP_SERVER" == true ] && install_standalone_sftp_server
  [ "$INSTALL_MARIADB" == true ] && install_mariadb

  # return true if script has made it this far
  return 0
}

function main {
  # check if we can detect an already existing installation
  if [ -d "/srv/daemon" ]; then
    print_warning "The script has detected that you already have Pterodactyl daemon on your system! You cannot run the script multiple times, it will fail!"
    echo -e -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      print_error "Installation aborted!"
      exit 1
    fi
  fi

  # detect distro
  detect_distro

  # checks if the system is compatible with this installation script
  check_os_comp

  print_brake 70
  echo "* Pterodactyl daemon installation script"
  echo "*"
  echo "* Copyright (C) 2018 - 2020, Vilhelm Prytz, <vilhelm@prytznet.se>, et al."
  echo "* https://github.com/vilhelmprytz/pterodactyl-installer"
  echo "*"
  echo "* This script is not associated with the official Pterodactyl Project."
  echo "*"
  echo "* Running $OS version $OS_VER."
  print_brake 70

  echo "* "
  echo "* The installer will install Docker, required dependencies for the daemon"
  echo "* as well as the daemon itself. But it's still required to create the node"
  echo "* on the panel and then place the configuration file on the node manually after"
  echo "* the installation has finished. Read more about this process on the"
  echo "* official documentation: https://pterodactyl.io/daemon/installing.html#configure-daemon"
  echo "* "
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not start the daemon automatically (will install systemd service, not start it)."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: this script will not enable swap (for docker)."
  print_brake 42

  echo -n "* Would you like to install the standalone SFTP server after daemon has installed? (y/N): "

  read -r CONFIRM_STANDALONE_SFTP_SERVER
  [[ "$CONFIRM_STANDALONE_SFTP_SERVER" =~ [Yy] ]] && INSTALL_STANDALONE_SFTP_SERVER=true

  echo -e "* ${COLOR_RED}Note${COLOR_NC}: If you installed the Pterodactyl panel on the same machine, do not use this option or the script will fail!"
  echo -n "* Would you like to install MariaDB (MySQL) server on the daemon as well? (y/N): "

  read -r CONFIRM_INSTALL_MARIADB
  [[ "$CONFIRM_INSTALL_MARIADB" =~ [Yy] ]] && INSTALL_MARIADB=true

  echo -n "* Proceed with installation? (y/N): "

  read -r CONFIRM
  [[ "$CONFIRM" =~ [Yy] ]] && perform_install && return

  print_error "Installation aborted"
  exit 0
}

function goodbye {
  echo ""
  print_brake 70
  echo "* Installation completed."
  echo ""
  echo "* Make sure you create the node within the panel and then copy"
  echo "* the config to this node. You may then start the daemon using "
  echo "* systemctl start wings"
  echo "* "
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: It is recommended to enable swap (for Docker, read more about it in official documentation)."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: This script does not configure your firewall. Ports 8080 and 2022 needs to be open."
  print_brake 70
  echo ""
}

# run script
main
goodbye
