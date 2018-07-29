#!/bin/bash
# pterodactyl-installer daemon
# Copyright Vilhelm Prytz 2018
# https://github.com/mrkakisen/pterodactyl-installer

# check if user is root or not
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges (sudo)." 1>&2
  exit 1
fi
