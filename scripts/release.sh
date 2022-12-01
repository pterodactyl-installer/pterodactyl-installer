#!/bin/bash

RELEASE=$1
DATE=$(date +%F)

COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m'

output() {
  echo -e "* $1"
}

error() {
  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1" 1>&2
  echo ""
}

[ -z "$RELEASE" ] && error "Mising release variable" && exit 1

output "Releasing $RELEASE on $DATE"

sed -i "/next-release/c\## $RELEASE (released on $DATE)" CHANGELOG.md

# install.sh
sed -i "s/.*SCRIPT_RELEASE=.*/SCRIPT_RELEASE=\"$RELEASE\"/" install.sh
sed -i "s/.*GITHUB_SOURCE=.*/GITHUB_SOURCE=\"$RELEASE\"/" install.sh

output "Commit release"

git add .
git commit -S -m "Release $RELEASE"
git push

output "Release $RELEASE pushed"

output "Create a new release, with changelog below - https://github.com/pterodactyl-installer/pterodactyl-installer/releases/new"
output ""

changelog=$(scripts/changelog_parse.py)

cat <<EOF
# $RELEASE

Put a message here describing the release.

## Changelog

$changelog
EOF
