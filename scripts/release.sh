#!/bin/bash

set -e -o pipefail

RELEASE=${1:-}
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

if [[ ! "$RELEASE" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  error "Release must use the format vX.Y.Z"
  exit 1
fi

cd "$(dirname "$0")/.."

if ! git diff --cached --quiet; then
  error "Commit or unstage existing staged changes before releasing."
  exit 1
fi

grep -qx '## next-release' CHANGELOG.md
grep -q '^export SCRIPT_RELEASE=' install.sh
grep -q '^export GITHUB_SOURCE=' install.sh

output "Releasing $RELEASE on $DATE"

sed -i "/^## next-release$/c\## $RELEASE (released on $DATE)" CHANGELOG.md

# install.sh
sed -i "s/^export SCRIPT_RELEASE=.*/export SCRIPT_RELEASE=\"$RELEASE\"/" install.sh
sed -i "s/^export GITHUB_SOURCE=.*/export GITHUB_SOURCE=\"$RELEASE\"/" install.sh

changelog=$(scripts/changelog_parse.py)

output "Commit release"

git add -- CHANGELOG.md install.sh
git commit -S -m "Release $RELEASE"
git push

output "Release $RELEASE pushed"

output "Create a new release with tag $RELEASE targeting the pushed release commit - https://github.com/pterodactyl-installer/pterodactyl-installer/releases/new"
output ""

cat <<EOF
# $RELEASE

Put a message here describing the release.

## Changelog

$changelog
EOF
