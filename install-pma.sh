#!/bin/bash
# shellcheck source=/dev/null

set -e


#### General checks ####

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


#### Variables ####

SCRIPT_VERSION="v0.9.1"
PMA_VERSION="5.1.1"
FQDN=""

#### Directory for installing PMA ####

DEFAULT_DIR="/var/www/phpmyadmin"

#### Default MySQL credentials ####

MYSQL_DB="phpmyadmin"
MYSQL_USER="admin"
MYSQL_PASSWORD=""


#### download URL

PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/$PMA_VERSION/phpMyAdmin-$PMA_VERSION-all-languages.tar.gz"

# Assume SSL, will fetch different config if true
ASSUME_SSL=false
CONFIGURE_LETSENCRYPT=false

# ufw firewall
CONFIGURE_UFW=false

# firewall_cmd
CONFIGURE_FIREWALL_CMD=false

# firewall status
CONFIGURE_FIREWALL=false

#### Visual functions ####


#### Colors ####

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
red='\033[0;31m'
reset="\e[0m"

print_error() {
  COLOR_RED='\033[0;31m'
  COLOR_NC='\033[0m'

  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1"
  echo ""
}

print_warning() {
  COLOR_YELLOW='\033[1;33m'
  COLOR_NC='\033[0m'
  echo ""
  echo -e "* ${COLOR_YELLOW}WARNING${COLOR_NC}: $1"
  echo ""
}

print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

password_input() {
  local __resultvar=$1
  local result=''
  local default="$4"

  while [ -z "$result" ]; do
    echo -n "* ${2}"

    # modified from https://stackoverflow.com/a/22940001
    while IFS= read -r -s -n1 char; do
      [[ -z $char ]] && {
        printf '\n'
        break
      }                               # ENTER pressed; output \n and break.
      if [[ $char == $'\x7f' ]]; then # backspace was pressed
        # Only if variable is not empty
        if [ -n "$result" ]; then
          # Remove last char from output variable.
          [[ -n $result ]] && result=${result%?}
          # Erase '*' to the left.
          printf '\b \b'
        fi
      else
        # Add typed char to output variable.
        result+=$char
        # Print '*' in its stead.
        printf '*'
      fi
    done
    [ -z "$result" ] && [ -n "$default" ] && result="$default"
    [ -z "$result" ] && print_error "${3}"
  done

  eval "$__resultvar="'$result'""
}

#### OS check funtions ####

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

#### Create all necessary folders ####

create_folders() {
mkdir -p /etc/phpmyadmin/upload
mkdir -p /etc/phpmyadmin/save
mkdir -p /etc/phpmyadmin/tmp
mkdir -p /var/www/phpmyadmin/tmp
}

#### Define permisions ####

define_permisions() {
chmod -R 660  /etc/phpmyadmin/*
chmod -R 777 /var/www/phpmyadmin/tmp
case "$OS" in
debian | ubuntu)
    chown -R www-data.www-data /var/www/phpmyadmin/*
    chown -R www-data.www-data /etc/phpmyadmin/*
;;
centos)
    chown -R nginx:nginx /var/www/phpmyadmin/*
    chown -R nginx:nginx /etc/phpmyadmin/*
;;
esac
}


# Download the PMA files #

pma_dl() {
echo "* Downloading the phpmyadmin files..."
cd /var/www/phpmyadmin

curl -Lo phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz "$PMA_URL"
tar -xzvf phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PMA_VERSION}"-all-languages
mv -- * "$DEFAULT_DIR"
cd "$DEFAULT_DIR"
rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz && rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages && rm -r config.sample.inc.php
}

main() {

# check if we can detect an already existing installation
  if [ -d "/var/www/phpmyadmin" ]; then
    print_warning "The script has detected that you already have PMA panel on your system! You cannot run the script multiple times, it will fail!"
    echo -e -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      print_error "Installation aborted!"
      exit 1
    fi
  fi

#### detect distro ####

detect_distro

#### Set FQDN ####

while [ -z "$FQDN" ]; do
  echo -n "* Enter the FQDN here to access your PMA (pma.mydomain.com): "
  read -r FQDN
  [ -z "$FQDN" ] && print_error "FQDN cannot be empty"
done

#### Create Credentials ####

echo
print_brake 52
echo "* Let's create a login user on the phpMyAdmin page."
print_brake 52
echo
echo -n -e "* Username (${YELLOW}admin${reset}): "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSQL_USER_INPUT

echo
echo -n -e "* Password (${YELLOW}pmapassword${reset}): "
read -r MYSQL_PASS_INPUT
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASSWORD="pmapassword" || MYSQL_PASSWORD=$MYSQL_PASSWORD_INPUT
if [ "$MYSQL_PASSWORD" == "pmapassword" ]; then
  print_warning "You are using the default password for PMA access, are you sure you want to continue with this password? (Y/N)"
  read -r UPDATE_MYSQL_PASS
    if [[ "$UPDATE_MYSQL_PASS" =~ [Yy] ]]; then
        echo
      else
        update_password
    fi
fi

#### Ask Firewall ####

ask_firewall

#### Ask Letsencrypt ####

ask_letsencrypt

# If it's already true, this should be a no-brainer
[ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl
}

update_password() {
while [ -z "$MYSQL_PASS_INPUT" ]; do
echo -e "New Password: "
#password_input MYSQL_PASS_INPUT "New Password: " "The password cannot be empty!"
read -r MYSQL_PASS_INPUT
if [ "$MYSQL_PASSWORD" == "pmapassword" ]; then
  print_warning "You need to enter a new password to continue!"
fi
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASSWORD="pmapassword" || MYSQL_PASSWORD=$MYSQL_PASSWORD_INPUT
echo
done
}

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    print_warning "Let's Encrypt requires port 80/443 to be opened! You have opted out of the automatic firewall configuration; use this at your own risk (if port 80/443 is closed, the script will fail)!"
  fi

  print_warning "You cannot use Let's Encrypt with your hostname as an IP address! It must be a FQDN (e.g. panel.example.org)."

  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=false
  fi
}

ask_assume_ssl() {
  echo "* Let's Encrypt is not going to be automatically configured by this script (user opted out)."
  echo "* You can 'assume' Let's Encrypt, which means the script will download a nginx configuration that is configured to use a Let's Encrypt certificate but the script won't obtain the certificate for you."
  echo "* If you assume SSL and do not obtain the certificate, your installation will not work."
  echo -n "* Assume SSL or not? (y/N): "
  read -r ASSUME_SSL_INPUT

  [[ "$ASSUME_SSL_INPUT" =~ [Yy] ]] && ASSUME_SSL=true
  true
}

ask_firewall() {
  case "$OS" in
  ubuntu | debian)
    echo -e -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
    read -r CONFIRM_UFW

    if [[ "$CONFIRM_UFW" =~ [Yy] ]]; then
      CONFIGURE_UFW=true
      CONFIGURE_FIREWALL=true
    fi
    ;;
  centos)
    echo -e -n "* Do you want to automatically configure firewall-cmd (firewall)? (y/N): "
    read -r CONFIRM_FIREWALL_CMD

    if [[ "$CONFIRM_FIREWALL_CMD" =~ [Yy] ]]; then
      CONFIGURE_FIREWALL_CMD=true
      CONFIGURE_FIREWALL=true
    fi
    ;;
  esac
}

#### Create a databse with user ####

create_database() {
  if [ "$OS" == "centos" ]; then
    # secure MariaDB
    echo "* MariaDB secure installation. The following are safe defaults."
    echo "* Set root password? [Y/n] Y"
    echo "* Remove anonymous users? [Y/n] Y"
    echo "* Disallow root login remotely? [Y/n] Y"
    echo "* Remove test database and access to it? [Y/n] Y"
    echo "* Reload privilege tables now? [Y/n] Y"
    echo "*"

    [ "$OS_VER_MAJOR" == "7" ] && mariadb-secure-installation
    [ "$OS_VER_MAJOR" == "8" ] && mysql_secure_installation

    echo "* The script should have asked you to set the MySQL root password earlier (not to be confused with the pterodactyl database user password)"
    echo "* MySQL will now ask you to enter the password before each command."

    echo "* Create MySQL user."
    mysql -u root -p -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    echo "* Create database."
    mysql -u root -p -e "CREATE DATABASE ${MYSQL_DB};"

    echo "* Grant privileges."
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION;"

    echo "* Flush privileges."
    mysql -u root -p -e "FLUSH PRIVILEGES;"
  else
    echo "* Performing MySQL queries.."

    echo "* Creating MySQL user.."
    mysql -u root -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    echo "* Creating database.."
    mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"

    echo "* Granting privileges.."
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION;"

    echo "* Flushing privileges.."
    mysql -u root -e "FLUSH PRIVILEGES;"

    echo "* MySQL database created & configured!"
  fi
}


#### Exec Script ####

main
create_folders
define_permisions
pma_dl
create_database