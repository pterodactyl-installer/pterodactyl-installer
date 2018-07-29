#!/bin/bash
# pterodactyl-installer daemon
# Copyright Vilhelm Prytz 2018
# https://github.com/mrkakisen/pterodactyl-installer

# check if user is root or not
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges (sudo)." 1>&2
  exit 1
fi

# variables
OS="debian"

# visual functions
function print_error {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

# other functions
function detect_distro {
  OS="$(python -c 'import platform ; print platform.dist()[0]')" | awk '{print tolower($0)}'
}

############################
## INSTALLATION FUNCTIONS ##
############################
function yum_update {
  yum update -y
}

function apt_update {
  apt update -y
  apt upgrade -y
}

function install_dep {
  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    apt_update

    # install dependencies
    apt -y install tar unzip make gcc g++ python
  elif [ "$OS" == "centos" ]; then
    yum_update

    # install dependencies
    yum -y install tar unzip make gcc-g++
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
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

    # show fingerprint to user
    apt-key fingerprint 0EBFCD88

    # add APT repo
    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/debian \
      $(lsb_release -cs) \
      stable"

    # install docker
    apt-get update
    apt-get -y install docker-ce

    # make sure it's enabled & running
    systemctl start docker
    systemctl enable docker

  elif [ "$OS" == "ubuntu" ]; then
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
    # install dependencies for Docker
    yum install -y yum-utils \
      device-mapper-persistent-data \
      lvm2

    # add repo to yum
    yum-config-manager \
      --add-repo \
      https://download.docker.com/linux/centos/docker-ce.repo

    # install Docker
    yum install -y docker-ce

    # make sure it's enabled & running
    systemctl start docker
    systemctl enable docker
  fi

  echo "* Docker has now been installed."
}

function install_nodejs {
  if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
    apt -y install nodejs
  elif [ "$OS" == "centos" ]; then
    curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
    yum -y install nodejs
  fi
}

function ptdl_dl {
  echo "* Installing pterodactyl daemon .. "
  mkdir -p /srv/daemon /srv/daemon-data
  cd /srv/daemon

  curl -L https://github.com/pterodactyl/daemon/releases/download/v0.5.6/daemon.tar.gz | tar --strip-components=1 -xzv
  npm install --only=production

  echo "* Done."
}

function systemd_file {
  echo "* Installing systemd service.."
  curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/MrKaKisen/pterodactyl-installer/master/configs/wings.service
  systemctl daemon-reload
  systemctl enable wings
  echo "* Installed systemd service!"
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
}

function main {
  echo "########################################"
  echo "* Pterodactyl daemon installation script "
  echo "* Detecting operating system."
  detect_distro
  echo "* Running $OS."
  echo "#########################################"
  echo "* The installer will install Docker, required dependencies for the daemon"
  echo "* as well as the daemon itself. But it is till required to create the node"
  echo "* on the panel and then place the configuration on the node after the"
  echo "* installation finishes. Read more here:"
  echo "* https://pterodactyl.io/daemon/installing.html#configure-daemon"
  echo "#########################################"
  echo -n "* Proceed with installation? (y/n): "

  read CONFIRM

  if [ "$CONFIRM" == "y" ]; then
    perform_install
  elif [ "$CONFIRM" == "n" ]; then
    exit 0
  else
    print_error "Invalid input"
    exit 1
  fi
}

function goodbye {
  echo ""
  echo "############################"
  echo "* Installation finished."
  echo ""
  echo "* Make sure you create the node within the panel and then "
  echo "* copy the config to the node. You may then start the daemon using "
  echo "* systemctl start wings"
  echo "############################"
  echo ""
}

# run main
main
goodbye
