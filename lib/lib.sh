#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'pterodactyl-installer'                                                    #
#                                                                                    #
# Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>                    #
#                                                                                    #
#   This program is free software: you can redistribute it and/or modify             #
#   it under the terms of the GNU General Public License as published by             #
#   the Free Software Foundation, either version 3 of the License, or                #
#   (at your option) any later version.                                              #
#                                                                                    #
#   This program is distributed in the hope that it will be useful,                  #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of                   #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                    #
#   GNU General Public License for more details.                                     #
#                                                                                    #
#   You should have received a copy of the GNU General Public License                #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.           #
#                                                                                    #
# https://github.com/pterodactyl-installer/pterodactyl-installer/blob/master/LICENSE #
#                                                                                    #
# This script is not associated with the official Pterodactyl Project.               #
# https://github.com/pterodactyl-installer/pterodactyl-installer                     #
#                                                                                    #
######################################################################################

# ------------------ Variables ----------------- #

# Versioning
export GITHUB_SOURCE=${GITHUB_SOURCE:-master}
export SCRIPT_RELEASE=${SCRIPT_RELEASE:-canary}

# Pterodactyl versions
export PANEL_MAJOR_VERSION="${PANEL_MAJOR_VERSION:-}"
export PTERODACTYL_PANEL_VERSION="${PTERODACTYL_PANEL_VERSION:-}"
export PTERODACTYL_PANEL_COMMIT="${PTERODACTYL_PANEL_COMMIT:-}"
export PTERODACTYL_WINGS_VERSION="${PTERODACTYL_WINGS_VERSION:-}"

# Path (export everything that is possible, doesn't matter that it exists already)
export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# OS
export OS=""
export OS_VER_MAJOR=""
export CPU_ARCHITECTURE=""
export ARCH=""
export SUPPORTED=false

# download URLs
export PANEL_DL_URL="${PANEL_DL_URL:-}"
export WINGS_DL_BASE_URL="${WINGS_DL_BASE_URL:-}"
export MARIADB_URL="https://downloads.mariadb.com/MariaDB/mariadb_repo_setup"
export GITHUB_BASE_URL=${GITHUB_BASE_URL:-"https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer"}
export GITHUB_URL="$GITHUB_BASE_URL/$GITHUB_SOURCE"

# Colors
COLOR_YELLOW=$'\033[1;33m'
COLOR_GREEN=$'\033[0;32m'
COLOR_RED=$'\033[0;31m'
COLOR_NC=$'\033[0m'

# email input validation regex
email_regex="^[A-Za-z0-9_+-]+(\.[A-Za-z0-9_+-]+)*@([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$"

# Charset used to generate random passwords
password_charset='A-Za-z0-9!#%&()*+,-./:;<=>?@[\]^_`{|}~'

# --------------------- Lib -------------------- #

lib_loaded() {
  return 0
}

# -------------- Visual functions -------------- #

output() {
  printf '* %s\n' "$1"
}

success() {
  echo ""
  output "${COLOR_GREEN}SUCCESS${COLOR_NC}: $1"
  echo ""
}

error() {
  echo ""
  printf '* %sERROR%s: %s\n' "$COLOR_RED" "$COLOR_NC" "$1" 1>&2
  echo ""
}

warning() {
  echo ""
  output "${COLOR_YELLOW}WARNING${COLOR_NC}: $1"
  echo ""
}

print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print_list() {
  print_brake 30
  for word in $1; do
    output "$word"
  done
  print_brake 30
  echo ""
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

# First argument is wings / panel / neither
welcome() {
  get_latest_versions "$1"

  print_brake 70
  output "Pterodactyl panel installation script @ $SCRIPT_RELEASE"
  output ""
  output "Copyright (C) 2018 - 2026, Vilhelm Prytz, <vilhelm@prytznet.se>"
  output "https://github.com/pterodactyl-installer/pterodactyl-installer"
  output ""
  output "This script is not associated with the official Pterodactyl Project."
  output ""
  output "Running $OS version $OS_VER."
  if [ "$1" == "panel" ]; then
    output "Selected pterodactyl/panel is $PTERODACTYL_PANEL_VERSION"
  elif [ "$1" == "wings" ]; then
    output "Latest pterodactyl/wings is $PTERODACTYL_WINGS_VERSION"
  fi
  print_brake 70
}

# ---------------- Lib functions --------------- #

ensure_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    update_repos
    install_packages "jq"
  fi
}

validate_panel_version() {
  PANEL_MAJOR_VERSION="${PANEL_MAJOR_VERSION:-1}"
  PANEL_MAJOR_VERSION="${PANEL_MAJOR_VERSION#v}"
  if [[ ! "$PANEL_MAJOR_VERSION" =~ ^[12]$ ]]; then
    error "PANEL_MAJOR_VERSION must be 1, v1, 2 or v2"
    return 1
  fi
}

ask_panel_version() {
  if [ -z "$PANEL_MAJOR_VERSION" ]; then
    while true; do
      echo -n "* Panel version: v1 (stable) or v2 (experimental) [1]: "
      read -r PANEL_MAJOR_VERSION
      PANEL_MAJOR_VERSION="${PANEL_MAJOR_VERSION:-1}"
      validate_panel_version && break
    done
  fi
  validate_panel_version || return 1
  if [[ "$PANEL_MAJOR_VERSION" == "2" ]]; then
    warning "Pterodactyl v2 is pre-release software."
    echo -n "* Install experimental Panel v2? (y/N): "
    read -r CONFIRM_EXPERIMENTAL
    if ! is_yes "$CONFIRM_EXPERIMENTAL"; then
      error "Installation aborted."
      exit 1
    fi
  fi
}

get_latest_release() {
  local repo="$1"
  local major="${2:-}"
  local releases tag
  local page=1
  if [ -z "$major" ]; then
    releases=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest") || return 1
    tag=$(jq -er 'select(.draft == false and .prerelease == false) | .tag_name' <<<"$releases") || return 1
  else
    while true; do
      releases=$(curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=100&page=$page") || return 1
      jq -e 'type == "array" and length > 0' <<<"$releases" >/dev/null || return 1
      tag=$(jq -r --arg major "$major" '[.[] | select(.draft == false and .prerelease == false) |
        .tag_name | select(test("^v" + $major + "\\.[0-9]+\\.[0-9]+$"))] |
        sort_by(ltrimstr("v") | split(".") | map(tonumber)) | last // empty' <<<"$releases") || return 1
      [ -n "$tag" ] && break
      page=$((page + 1))
    done
  fi
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  echo "$tag"
}

get_latest_versions() {
  local response
  case "${1:-}" in
  panel)
    validate_panel_version || return 1
    ensure_jq
    output "Retrieving Panel version information..."
    if [ "$PANEL_MAJOR_VERSION" == "2" ]; then
      if [ -z "$PTERODACTYL_PANEL_COMMIT" ]; then
        response=$(curl -fsSL https://api.github.com/repos/pterodactyl/panel/commits/2.0-develop) || return 1
        PTERODACTYL_PANEL_COMMIT=$(jq -er '.sha' <<<"$response") || return 1
      fi
      [[ "$PTERODACTYL_PANEL_COMMIT" =~ ^[0-9a-f]{40}$ ]] || return 1
      PTERODACTYL_PANEL_VERSION="2.0-develop@$PTERODACTYL_PANEL_COMMIT (experimental)"
      PANEL_DL_URL="https://github.com/pterodactyl/panel/archive/$PTERODACTYL_PANEL_COMMIT.tar.gz"
    else
      if [[ ! "$PTERODACTYL_PANEL_VERSION" =~ ^v1\.[0-9]+\.[0-9]+$ ]]; then
        PTERODACTYL_PANEL_VERSION=$(get_latest_release "pterodactyl/panel" 1) || return 1
      fi
      PANEL_DL_URL="https://github.com/pterodactyl/panel/releases/download/$PTERODACTYL_PANEL_VERSION/panel.tar.gz"
    fi
    ;;
  wings)
    ensure_jq
    output "Retrieving Wings release information..."
    if [ -z "$PTERODACTYL_WINGS_VERSION" ]; then
      PTERODACTYL_WINGS_VERSION=$(get_latest_release "pterodactyl/wings") || return 1
    fi
    [[ "$PTERODACTYL_WINGS_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    WINGS_DL_BASE_URL="https://github.com/pterodactyl/wings/releases/download/$PTERODACTYL_WINGS_VERSION/wings_linux_"
    ;;
  esac
}

update_lib_source() {
  GITHUB_URL="$GITHUB_BASE_URL/$GITHUB_SOURCE"
  rm -rf /tmp/lib.sh
  curl -fsSL -o /tmp/lib.sh "$GITHUB_URL"/lib/lib.sh
  # shellcheck source=lib/lib.sh
  source /tmp/lib.sh
}

run_installer() {
  local script
  script=$(curl -fsSL "$GITHUB_URL/installers/$1.sh") || return 1
  bash -e -o pipefail -c "$script"
}

run_ui() {
  local script
  script=$(curl -fsSL "$GITHUB_URL/ui/$1.sh") || return 1
  bash -e -o pipefail -c "$script"
}

array_contains_element() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

valid_email() {
  local local_part="${1%@*}"
  [[ ${#1} -le 191 && ${#local_part} -le 64 && "$1" =~ ${email_regex} ]]
}

is_ip_address() {
  local address="$1"
  if [[ "$address" == '['* || "$address" == *']' ]]; then
    [[ "$address" == '['*']' && "$address" == *:* ]] || return 1
    address="${address#[}"
    address="${address%]}"
  fi
  local part
  local parts
  local count=0
  if [[ "$address" == *:* ]]; then
    if [[ "$address" == *.* ]]; then
      is_ip_address "${address##*:}" || return 1
      address="${address%:*}:0:0"
    fi
    [[ "$address" != *[!0-9a-fA-F:]* && "$address" != *:::* ]] || return 1
    [[ "$address" != :* || "$address" == ::* ]] || return 1
    [[ "$address" != *: || "$address" == *:: ]] || return 1
    if [[ "$address" == *::* ]]; then
      [[ "${address#*::}" != *::* ]] || return 1
    fi
    IFS=: read -r -a parts <<<"$address"
    for part in "${parts[@]}"; do
      [ -z "$part" ] && continue
      [ "${#part}" -le 4 ] || return 1
      count=$((count + 1))
    done
    [[ "$address" == *::* && "$count" -lt 8 || "$count" == 8 && "$address" != *::* ]]
  else
    [[ "$address" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || return 1
    IFS=. read -r -a parts <<<"$address"
    for part in "${parts[@]}"; do
      [[ "$part" == 0 || "$part" != 0* ]] || return 1
      (( 10#$part <= 255 )) || return 1
    done
  fi
}

valid_hostname() {
  if is_ip_address "$1"; then
    return 0
  fi
  [[ ${#1} -le 253 && ! "$1" =~ ^[0-9.]+$ && "$1" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.?$ ]] || {
    error "Enter a valid hostname or IP address."
    return 1
  }
}

check_install_settings() {
  [ -f "$INSTALL_SETTINGS" ] && [ ! -L "$INSTALL_SETTINGS" ] && [ -O "$INSTALL_SETTINGS" ] &&
    [[ "$(stat -c %a "$INSTALL_SETTINGS")" =~ ^[46]00$ ]] &&
    [ "$(stat -c %s "$INSTALL_SETTINGS")" -le 4096 ] || {
    error "INSTALL_SETTINGS must be a regular file owned by root with mode 400 or 600 (maximum 4096 bytes)."
    return 1
  }
}

load_install_settings() {
  check_install_settings || return 1
  if LC_ALL=C grep -aq '[^ -~]' "$INSTALL_SETTINGS"; then
    error "INSTALL_SETTINGS must contain plain ASCII text without control characters."
    return 1
  fi
  local key value
  local seen=" "
  local count=0
  while IFS='=' read -r key value || [ -n "$key$value" ]; do
    case "$key" in
    CONFIGURE_FIREWALL | CONFIGURE_LETSENCRYPT | ASSUME_SSL)
      [[ "$value" =~ ^(true|false)$ ]] || return 1
      ;;
    FQDN)
      valid_hostname "$value" || return 1
      ;;
    EMAIL)
      valid_email "$value" || return 1
      ;;
    PANEL_MAJOR_VERSION)
      [[ "$value" =~ ^[12]$ ]] || return 1
      ;;
    *)
      error "Invalid INSTALL_SETTINGS entry."
      return 1
      ;;
    esac
    if [[ "$seen" == *" $key "* ]]; then
      error "Duplicate INSTALL_SETTINGS entry."
      return 1
    fi
    seen+="$key "
    count=$((count + 1))
    printf -v "$key" '%s' "$value"
  done <"$INSTALL_SETTINGS"
  if [ "$count" != 6 ]; then
    error "INSTALL_SETTINGS is incomplete."
    return 1
  fi
  if [ "$CONFIGURE_LETSENCRYPT" == true ] && { is_ip_address "$FQDN" || [ "$FQDN" == localhost ]; }; then
    error "INSTALL_SETTINGS cannot enable Let's Encrypt for an IP address or localhost."
    return 1
  fi
  return 0
}

verify_fqdn() {
  local script
  script=$(curl -fsSL "$GITHUB_URL/lib/verify-fqdn.sh") || return 1
  bash -e -o pipefail -c "$script" -- "$1"
}

gen_passwd() {
  local length=$1
  local password=""
  while [ ${#password} -lt "$length" ]; do
    password=$(echo "$password""$(head -c 100 /dev/urandom | LC_ALL=C tr -dc "$password_charset")" | fold -w "$length" | head -n 1)
  done
  echo "$password"
}

# -------------------- MYSQL ------------------- #

check_database_connection() {
  mariadb -u root -e "SELECT 1;" >/dev/null || {
    error "Cannot connect to MariaDB as root. Configure root access in $HOME/.my.cnf before running the installer."
    return 1
  }
}

# MariaDB 10.3 on EL8 only provides the legacy mysql client name.
mariadb() {
  if type -P mariadb >/dev/null 2>&1; then
    command mariadb "$@"
  else
    command mysql "$@"
  fi
}

create_db_user() {
  local db_user_name="$1"
  local db_user_password="$2"
  local db_host="${3:-127.0.0.1}"
  db_user_password="${db_user_password//\'/\'\'}"

  output "Creating database user $db_user_name..."

  mariadb -u root -e "SET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES'; CREATE USER '$db_user_name'@'$db_host' IDENTIFIED BY '$db_user_password';"
  mariadb -u root -e "FLUSH PRIVILEGES;"

  output "Database user $db_user_name created"
}

grant_all_privileges() {
  local db_name="$1"
  local db_user_name="$2"
  local db_host="${3:-127.0.0.1}"
  local db_identifier="\`$db_name\`"
  [ "$db_name" != "*" ] || db_identifier="*"

  output "Granting all privileges on $db_name to $db_user_name..."

  mariadb -u root -e "GRANT ALL PRIVILEGES ON $db_identifier.* TO '$db_user_name'@'$db_host' WITH GRANT OPTION;"
  mariadb -u root -e "FLUSH PRIVILEGES;"

  output "Privileges granted"

}

create_db() {
  local db_name="$1"
  local db_user_name="$2"
  local db_host="${3:-127.0.0.1}"

  output "Creating database $db_name..."

  mariadb -u root -e "CREATE DATABASE \`$db_name\`;"
  grant_all_privileges "$db_name" "$db_user_name" "$db_host"

  output "Database $db_name created"
}

# --------------- Package Manager -------------- #

update_repos() {
  local args=""
  
  [[ "$1" == true ]] && args="-qq"

  case "$OS" in
    ubuntu | debian)
      output "Updating package repositories..."
      if ! apt-get update -y $args; then
        error "Failed to update repositories."
        return 1
      fi
      ;;
    rocky | almalinux)
      # Skip since these distros auto-refresh metadata
      output "Skipping repository update (handled automatically on $OS)."
      ;;
    *)
      warning "Unsupported OS: $OS — skipping repository update."
      ;;
  esac
}


# First argument list of packages to install, second argument for quite mode
install_packages() {
  local args=""
  if [[ $2 == true ]]; then
    case "$OS" in
    ubuntu | debian) args="-qq" ;;
    *) args="-q" ;;
    esac
  fi

  # Eval needed for proper expansion of arguments
  case "$OS" in
  ubuntu | debian)
    eval apt-get -y $args install "$1"
    ;;
  rocky | almalinux)
    eval dnf -y $args install "$1"
    ;;
  esac
}

# ------------ User input functions ------------ #

valid_database_identifier() {
  [[ "$1" =~ ^[a-zA-Z0-9_]+$ && ${#1} -le 64 ]] || {
    error "Database names and usernames must contain only letters, numbers and underscores (maximum 64 characters)."
    return 1
  }
}

valid_admin_username() {
  [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]+[a-zA-Z0-9]$ && ${#1} -le 191 ]] || {
    error "Username must be 3-191 characters, start and end with a letter or number, and contain only letters, numbers, dashes, underscores and periods."
    return 1
  }
}

valid_admin_name() {
  [[ "$1" =~ [^[:space:]] && ! "$1" =~ [[:cntrl:]] && ${#1} -le 191 ]] || {
    error "Name must be 1-191 characters without control characters."
    return 1
  }
}

valid_admin_password() {
  [[ ${#1} -ge 8 && "$1" =~ [^[:space:]] && ! "$1" =~ [[:cntrl:]] ]] || {
    error "Admin password must contain at least 8 characters and cannot be blank or contain control characters."
    return 1
  }
}

valid_panel_database_password() {
  [[ "$1" =~ [^[:space:]] && "$1" != *"'"* && "$1" != *'"'* && "$1" != *\\* && "$1" != *'$'* && ! "$1" =~ [[:cntrl:]] ]] || {
    error "Panel database password cannot be blank or contain quotes, backslashes, dollar signs or control characters."
    return 1
  }
}

is_yes() {
  [[ "$1" =~ ^[Yy]([Ee][Ss])?$ ]]
}

required_input() {
  local __resultvar=$1
  local result=''

  while [ -z "$result" ]; do
    echo -n "* ${2}"
    read -r result

    if [ -z "${3}" ]; then
      [ -z "$result" ] && result="${4}"
    else
      [ -z "$result" ] && error "${3}"
    fi
  done

  printf -v "$__resultvar" '%s' "$result"
}

email_input() {
  local __resultvar=$1
  local result=''

  while ! valid_email "$result"; do
    echo -n "* ${2}"
    read -r result
    [ -z "$result" ] && result="${4}"

    valid_email "$result" || error "${3}"
  done

  printf -v "$__resultvar" '%s' "$result"
}

password_input() {
  local __resultvar=$1
  local result=''
  local default="$4"

  while [ -z "$result" ]; do
    echo -n "* ${2}"

    # modified from https://stackoverflow.com/a/22940001
    while true; do
      IFS= read -r -s -n1 char || return 1
      [[ -z $char ]] && {
        printf '\n'
        break
      }                               # ENTER pressed; output \n and break.
      if [[ $char == $'\x7f' ]]; then # backspace was pressed
        # Only if variable is not empty
        if [ -n "$result" ]; then
          # Remove last char from output variable.
          result=${result%?}
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
    [ -z "$result" ] && error "${3}"
  done

  printf -v "$__resultvar" '%s' "$result"
}

ask_letsencrypt() {
  if [ "$CONFIGURE_FIREWALL" == false ]; then
    warning "Let's Encrypt requires port 80/443 to be opened! You have opted out of the automatic firewall configuration; use this at your own risk (if port 80/443 is closed, the script will fail)!"
  fi

  echo -e -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL

  if is_yes "$CONFIRM_SSL"; then
    export CONFIGURE_LETSENCRYPT=true
  fi
}

# ------------------ Firewall ------------------ #

ask_firewall() {
  local __resultvar=$1

  case "$OS" in
  ubuntu | debian)
    echo -e -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
    read -r CONFIRM_UFW

    if is_yes "$CONFIRM_UFW"; then
      printf -v "$__resultvar" '%s' true
    fi
    ;;
  rocky | almalinux)
    echo -e -n "* Do you want to automatically configure firewall-cmd (firewall)? (y/N): "
    read -r CONFIRM_FIREWALL_CMD

    if is_yes "$CONFIRM_FIREWALL_CMD"; then
      printf -v "$__resultvar" '%s' true
    fi
    ;;
  esac
}

install_firewall() {
  case "$OS" in
  ubuntu | debian)
    output ""
    output "Installing Uncomplicated Firewall (UFW)"

    if ! [ -x "$(command -v ufw)" ]; then
      update_repos true
      install_packages "ufw" true
    fi

    ufw --force enable

    success "Enabled Uncomplicated Firewall (UFW)"

    ;;
  rocky | almalinux)

    output ""
    output "Installing FirewallD"+

    if ! [ -x "$(command -v firewall-cmd)" ]; then
      install_packages "firewalld" true
    fi

    systemctl --now enable firewalld >/dev/null

    success "Enabled FirewallD"

    ;;
  esac
}

firewall_allow_ports() {
  case "$OS" in
  ubuntu | debian)
    for port in $1; do
      ufw allow "$port"
    done
    ufw --force reload
    ;;
  rocky | almalinux)
    for port in $1; do
      firewall-cmd --zone=public --add-port="$port"/tcp --permanent
    done
    firewall-cmd --reload -q
    ;;
  esac
}

# ---------------- System checks --------------- #

# panel x86_64 check
check_os_x86_64() {
  if [ "${ARCH}" != "amd64" ]; then
    warning "Detected CPU architecture $CPU_ARCHITECTURE"
    warning "Using any other architecture than 64 bit (x86_64) will cause problems."

    echo -e -n "* Are you sure you want to proceed? (y/N):"
    read -r choice

    if ! is_yes "$choice"; then
      error "Installation aborted!"
      exit 1
    fi
  fi
}

# wings virtualization check
check_virt() {
  output "Installing virt-what..."

  update_repos true
  install_packages "virt-what" true

  virt_serv=$(virt-what)

  case "$virt_serv" in
  *openvz* | *lxc*)
    warning "Unsupported type of virtualization detected. Please consult with your hosting provider whether your server can run Docker or not. Proceed at your own risk."
    echo -e -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if ! is_yes "$CONFIRM_PROCEED"; then
      error "Installation aborted!"
      exit 1
    fi
    ;;
  *)
    [ "$virt_serv" != "" ] && warning "Virtualization: $virt_serv detected."
    ;;
  esac

  if uname -r | grep -q "xxxx"; then
    error "Unsupported kernel detected."
    exit 1
  fi

  success "System is compatible with docker"
}

# Exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  error "This script must be executed with root privileges."
  exit 1
fi

if [ -z "$HOME" ]; then
  error "HOME must be set before running this script."
  exit 1
fi

# Detect OS
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
if [ "$OS" == "debian" ] && [ -z "$OS_VER" ] && [ -f /etc/debian_version ]; then
  OS_VER=$(cat /etc/debian_version)
fi
OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
CPU_ARCHITECTURE=$(uname -m)

case "$CPU_ARCHITECTURE" in
x86_64)
  ARCH=amd64
  ;;
arm64 | aarch64)
  ARCH=arm64
  ;;
*)
  error "Only x86_64 and arm64 are supported!"
  exit 1
  ;;
esac

# Cache package and systemd unit differ between distribution families.
export CACHE_SERVICE="redis-server"
export PHP_BIN="/usr/bin/php8.3"
case "$OS" in
ubuntu)
  [ "$OS_VER_MAJOR" == "22" ] && SUPPORTED=true
  [ "$OS_VER_MAJOR" == "24" ] && SUPPORTED=true
  [ "$OS_VER_MAJOR" == "26" ] && SUPPORTED=true
  export DEBIAN_FRONTEND=noninteractive
  ;;
debian)
  [ "$OS_VER_MAJOR" == "12" ] && SUPPORTED=true
  [ "$OS_VER_MAJOR" == "13" ] && SUPPORTED=true
  export DEBIAN_FRONTEND=noninteractive
  ;;
rocky | almalinux)
  [ "$OS_VER_MAJOR" == "8" ] && SUPPORTED=true
  [ "$OS_VER_MAJOR" == "9" ] && SUPPORTED=true
  [ "$OS_VER_MAJOR" == "10" ] && SUPPORTED=true
  PHP_BIN="/usr/bin/php"
  CACHE_SERVICE="redis"
  [ "$OS_VER_MAJOR" == "10" ] && CACHE_SERVICE="valkey"
  ;;
*)
  SUPPORTED=false
  ;;
esac

# exit if not supported
if [ "$SUPPORTED" == false ]; then
  output "$OS $OS_VER is not supported"
  error "Unsupported OS"
  exit 1
fi
