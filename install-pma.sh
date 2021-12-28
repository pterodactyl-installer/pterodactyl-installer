#!/bin/bash
#shellcheck source=/dev/null

set -e

#### Main Variables ####

SUPPORT_LINK="https://discord.gg/m7kuHgttZj"
SCRIPT_VERSION="v0.9.1"
PMA_VERSION="5.1.1"

#### Download Url's ####

PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/$PMA_VERSION/phpMyAdmin-$PMA_VERSION-all-languages.tar.gz"
GITHUB_BASE_URL="https://raw.githubusercontent.com/vilhelmprytz/pterodactyl-installer/$SCRIPT_VERSION"


### Default Mysql Info ####

MYSQL_USER="admin"
MYSQL_PASSWORD="pmapassword"


#### FQDN ####

FQDN=""

#### Colors ####

YELLOW="\033[1;33m"
DEFAULT="\e[0m"


#### All Default Variables ####

CONFIGURE_UFW=false
CONFIGURE_FIREWALL_CMD=false

#### Directory for installing PMA ####

DEFAULT_DIR="/var/www/phpmyadmin"


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


check_os_comp() {
  CPU_ARCHITECTURE=$(uname -m)
  if [ "${CPU_ARCHITECTURE}" != "x86_64" ]; then # check the architecture
    print_warning "Detected CPU architecture $CPU_ARCHITECTURE"
    print_warning "Using any other architecture than 64 bit (x86_64) will cause problems."

    echo -e -n "* Are you sure you want to proceed? (y/N):"
    read -r choice

    if [[ ! "$choice" =~ [Yy] ]]; then
      print_error "Installation aborted!"
      exit 1
    fi
  fi

  case "$OS" in
  ubuntu)
    PHP_SOCKET="/run/php/php8.0-fpm.sock"
    [ "$OS_VER_MAJOR" == "18" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "20" ] && SUPPORTED=true
    ;;
  debian)
    PHP_SOCKET="/run/php/php8.0-fpm.sock"
    [ "$OS_VER_MAJOR" == "9" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "10" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "11" ] && SUPPORTED=true
    ;;
  centos)
    PHP_SOCKET="/var/run/php-fpm/phpmyadmin.sock"
    [ "$OS_VER_MAJOR" == "7" ] && SUPPORTED=true
    [ "$OS_VER_MAJOR" == "8" ] && SUPPORTED=true
    ;;
  *)
    SUPPORTED=false
    ;;
  esac

  # exit if not supported
  if [ "$SUPPORTED" == true ]; then
    echo "* $OS $OS_VER is supported."
  else
    echo "* $OS $OS_VER is not supported"
    print_error "Unsupported OS"
    exit 1
  fi
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

#### FQDN ####

FQDN() {
while [ -z "$FQDN" ]; do
  echo -n "* Set the FQDN of this panel ${YELLOW}(pma.example.com)${DEFAULT}: "
  read -r FQDN
  [ -z "$FQDN" ] && print_error "FQDN cannot be empty"
done
}


#### Create Credentials ####

create_credentials() {
echo
print_brake 52
echo "* Let's create a login user on the phpMyAdmin page."
print_brake 52
echo
echo -n -e "* Username (${YELLOW}admin${DEFAULT}): "
read -r MYSQL_USER_INPUT
[ -z "$MYSQL_USER_INPUT" ] && MYSQL_USER="admin" || MYSQL_USER=$MYSQL_USER_INPUT

echo
echo -n -e "* Password (${YELLOW}pmapassword${DEFAULT}): "
read -r MYSQL_PASS_INPUT
[ -z "$MYSQL_PASS_INPUT" ] && MYSQL_PASSWORD="pmapassword" || MYSQL_PASSWORD=$MYSQL_PASSWORD_INPUT
if [ "$MYSQL_PASSWORD" == "pmapassword" ]; then
  print_warning "You are using the default password for phpmyadmin access, remember to change it!"
fi
}


UFW() {
case "$OS" in
ubuntu | debian)
  echo -e -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
  read -r CONFIRM_UFW

  if [[ "$CONFIRM_UFW" =~ [Yy] ]]; then
    CONFIGURE_UFW=true
  fi
  ;;
centos)
  echo -e -n "* Do you want to automatically configure firewall-cmd (firewall)? (y/N): "
  read -r CONFIRM_FIREWALL_CMD

  if [[ "$CONFIRM_FIREWALL_CMD" =~ [Yy] ]]; then
    CONFIGURE_FIREWALL_CMD=true
  fi
  ;;
esac
}

Configure_Ufw() {
apt-get install -y ufw

echo -e "\n* Enabling Uncomplicated Firewall (UFW)"
echo "* Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

# pointing to /dev/null silences the command output
ufw allow ssh >/dev/null
ufw allow http >/dev/null
ufw allow https >/dev/null

ufw --force enable
ufw --force reload
ufw status numbered | sed '/v6/d'
}

Configure_Ufw_Cmd() {
echo -e "\n* Enabling firewall_cmd (firewalld)"
echo "* Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

# Install
[ "$OS_VER_MAJOR" == "7" ] && yum -y -q install firewalld >/dev/null
[ "$OS_VER_MAJOR" == "8" ] && dnf -y -q install firewalld >/dev/null

# Enable
systemctl --now enable firewalld >/dev/null # Enable and start

# Configure
firewall-cmd --add-service=http --permanent -q  # Port 80
firewall-cmd --add-service=https --permanent -q # Port 443
firewall-cmd --add-service=ssh --permanent -q   # Port 22
firewall-cmd --reload -q                        # Enable firewall

echo "* Firewall-cmd installed"
print_brake 70
}

#### Functions specific to each OS ####

enable_services_debian_based() {
systemctl enable mariadb
systemctl start mariadb
}

enable_services_centos_based() {
systemctl enable mariadb
systemctl enable nginx
systemctl start mariadb
}

selinux_allow() {
  setsebool -P httpd_can_network_connect 1 || true # these commands can fail OK
  setsebool -P httpd_execmem 1 || true
  setsebool -P httpd_unified 1 || true
}

ubuntu18_dep() {
# PHP and MariaDB Repositorys #
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Update Repository #
apt-get -y update

# Add Universe Repository #
apt-add-repository universe

# Install All Dependencies #
apt-get -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx
}

ubuntu20_dep() {
# PHP and MariaDB Repositorys #
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Update Repository #
apt-get -y update

# Install All Dependencies #
apt-get -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx
}

debian9_dep() {
echo "* Installing dependencies for Debian 8/9.."

# MariaDB need dirmngr
apt -y install dirmngr

# install PHP 8.0 using sury's repo instead of PPA
apt install ca-certificates apt-transport-https lsb-release -y
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

# Add the MariaDB repo (oldstable has mariadb version 10.1 and we need newer than that)
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

# Update repositories list
apt-get -y update

# Install Dependencies
apt-get -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

# Enable services
enable_services_debian_based

echo "* Dependencies for Debian 8/9 installed!"
}

debian10_dep() {
echo "* Installing dependencies for Debian 10.."

# MariaDB need dirmngr
apt -y install dirmngr

# install PHP 8.0 using sury's repo instead of default 7.2 package (in buster repo)
# this guide shows how: https://vilhelmprytz.se/2018/08/22/install-php72-on-Debian-8-and-9.html
apt install ca-certificates apt-transport-https lsb-release -y
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

# Update repositories list
apt-get -y update

# install dependencies
apt-get -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

# Enable services
enable_services_debian_based

echo "* Dependencies for Debian 10 installed!"
}

debian11_dep() {
echo "* Installing dependencies for Debian 11.."

# MariaDB need dirmngr
apt -y install dirmngr

# install PHP 8.0 using sury's repo instead of default 7.2 package (in buster repo)
# this guide shows how: https://vilhelmprytz.se/2018/08/22/install-php72-on-Debian-8-and-9.html
apt install ca-certificates apt-transport-https lsb-release -y
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

# Update repositories list
apt-get -y update

# install dependencies
apt-get -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx

# Enable services
enable_services_debian_based

echo "* Dependencies for Debian 11 installed!"
}

centos7_dep() {
echo "* Installing dependencies for CentOS 7.."

# SELinux tools
yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans

# Add remi repo (php8.0)
yum install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y yum-utils
yum-config-manager -y --disable remi-php54
yum-config-manager -y --enable remi-php80
yum_update

# Install MariaDB
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Install dependencies
yum -y install php php-common php-tokenizer php-curl php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server nginx

# Enable services
enable_services_centos_based

# SELinux (allow nginx and redis)
selinux_allow

echo "* Dependencies for CentOS installed!"
}

centos8_dep() {
echo "* Installing dependencies for CentOS 8.."

# SELinux tools
dnf install -y policycoreutils selinux-policy selinux-policy-targeted setroubleshoot-server setools setools-console mcstrans

# add remi repo (php8.0)
dnf install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module enable -y php:remi-8.0
dnf_update

dnf install -y php php-common php-fpm php-cli php-json php-mysqlnd php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache

# MariaDB (use from official repo)
dnf install -y mariadb mariadb-server

# Other dependencies
dnf install -y nginx

# Enable services
enable_services_centos_based

# SELinux (allow nginx and redis)
selinux_allow

echo "* Dependencies for CentOS installed!"
}


#### Configure Web-Server ####

configure_nginx() {
echo "* Configuring nginx .."

HTTP_FILE="nginx.conf"

if [ "$OS" == "centos" ]; then
  # remove default config
  rm -rf /etc/nginx/conf.d/default

  # download new config
  curl -o /etc/nginx/conf.d/phpmyadmin.conf $GITHUB_BASE_URL/configs/$HTTP_FILE

  # replace all <domain> places with the correct domain
  sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/phpmyadmin.conf

  # replace all <php_socket> places with correct socket "path"
  sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/conf.d/phpmyadmin.conf
else
  # remove default config
  rm -rf /etc/nginx/sites-enabled/default

  # download new config
  curl -o /etc/nginx/sites-available/phpmyadmin.conf $GITHUB_BASE_URL/configs/$HTTP_FILE

  # replace all <domain> places with the correct domain
  sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-available/phpmyadmin.conf

  # replace all <php_socket> places with correct socket "path"
  sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/sites-available/phpmyadmin.conf

  # on debian 9, TLS v1.3 is not supported (see #76)
  [ "$OS" == "debian" ] && [ "$OS_VER_MAJOR" == "9" ] && sed -i 's/ TLSv1.3//' /etc/nginx/sites-available/phpmyadmin.conf

  # enable phpmyadmin
  ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
fi

systemctl restart nginx

echo "* nginx configured!"
}

#### Install ####

install() {
echo "* Starting installation.. this might take a while!"

case "$OS" in
debian | ubuntu)
apt-get -y update

[ "$CONFIGURE_UFW" == true ] && Configure_Ufw

if [ "$OS" == "ubuntu" ]; then
    [ "$OS_VER_MAJOR" == "20" ] && ubuntu20_dep
    [ "$OS_VER_MAJOR" == "18" ] && ubuntu18_dep
  elif [ "$OS" == "debian" ]; then
    [ "$OS_VER_MAJOR" == "9" ] && debian9_dep
    [ "$OS_VER_MAJOR" == "10" ] && debian10_dep
    [ "$OS_VER_MAJOR" == "11" ] && debian11_dep
fi
;;

centos)
  [ "$OS_VER_MAJOR" == "7" ] && yum update -y
  [ "$OS_VER_MAJOR" == "8" ] && dnf update -y

  [ "$CONFIGURE_FIREWALL_CMD" == true ] && Configure_Ufw_Cmd

  [ "$OS_VER_MAJOR" == "7" ] && centos7_dep
  [ "$OS_VER_MAJOR" == "8" ] && centos8_dep
;;
esac

# Download All Files #

echo "* Downloading the phpmyadmin files..."

cd "$DEFAULT_DIR"
curl -Lo phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz "$PMA_URL"
tar -xzvf phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PMA_VERSION}"-all-languages
mv -- * "$DEFAULT_DIR"
cd "$DEFAULT_DIR"
rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz && rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages && rm -r config.sample.inc.php
}

create_database() {
case "$OS" in
debian | ubuntu)

  mysql -u root -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
  mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"
  mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'%';"
  mysql -u root -e "FLUSH PRIVILEGES;"
  cd "$DEFAULT_DIR/sql"
  mysql -u root "$MYSQL_DB" < create_tables.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_mysql_4_1_2+.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_4_7_0+.sql
;;
centos)
  [ "$OS_VER_MAJOR" == "7" ] && mariadb-secure-installation
  [ "$OS_VER_MAJOR" == "8" ] && mysql_secure_installation

  mysql -u root -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
  mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"
  mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'%';"
  mysql -u root -e "FLUSH PRIVILEGES;"
  cd "$DEFAULT_DIR/sql"
  mysql -u root "$MYSQL_DB" < create_tables.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_mysql_4_1_2+.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_4_7_0+.sql
;;
esac
FILE="$DEFAULT_DIR/config.inc.php"
if [ -f "$FILE" ]; then
  KEY="$(openssl rand -base64 32)"
  sed -i -e "s@<key>@$KEY@g" "$FILE"
  sed -i -e "s@<user>@$MYSQL_USER@g" "$FILE"
  sed -i -e "s@<password>@$MYSQL_PASSWORD@g" "$FILE"
fi
}


bye() {
print_brake 50
echo
echo -e "* ${GREEN}The ${YELLOW}PhpMyAdmin${GREEN} was successfully installed."
echo -e "* Thank you for using this script."
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${DEFAULT}"
echo
print_brake 50
}


#### Exec Script ####

detect_distro
create_folders
define_permisions
FQDN
UFW
install
create_database
bye
