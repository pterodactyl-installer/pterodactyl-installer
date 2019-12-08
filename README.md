# :bird: pterodactyl-installer

[![Build Status](https://travis-ci.org/VilhelmPrytz/pterodactyl-installer.svg?branch=master)](https://travis-ci.org/VilhelmPrytz/utbildningsmaterial)
[![License: GPL v3](https://img.shields.io/github/license/VilhelmPrytz/pterodactyl-installer)](LICENSE)

Unofficial scripts for installing Pterodactyl on both Panel & Daemon.

Read more about [Pterodactyl](https://pterodactyl.io/) here. This script is not associated with the official Pterodactyl Project.

## Supported installations

List of supported installation setups for panel and daemon (installations supported by this installation script).

### Supported panel operating systems and webservers

| Operating System  | Version | nginx support        | Apache support | PHP Version |
| ----------------- | ------- | -------------------- | -------------- | ----------- |
| Ubuntu            | 14.04   | :red_circle:         | :red_circle:   |             |
|                   | 16.04   | :white_check_mark:   | :red_circle:   | 7.2         |
|                   | 18.04   | :white_check_mark:   | :red_circle:   | 7.2         |
| Debian            | 8       | :white_check_mark:   | :red_circle:   | 7.3         |
|                   | 9       | :white_check_mark:   | :red_circle:   | 7.3         |
|                   | 10      | :white_check_mark:   | :red_circle:   | 7.3         |
| CentOS            | 6       | :red_circle:         | :red_circle:   |             |
|                   | 7       | :white_check_mark:   | :red_circle:   | 7.3         |
|                   | 8       | :white_check_mark:   | :red_circle:   | 7.2         |

### Supported daemon operating systems

| Operating System  | Version | Supported            |
| ----------------- | ------- | -------------------- |
| Ubuntu            | 14.04   | :red_circle:         |
|                   | 16.04   | :white_check_mark:   |
|                   | 18.04   | :white_check_mark:   |
| Debian            | 8       | :red_circle:         |
|                   | 9       | :white_check_mark:   |
|                   | 10      | :white_check_mark: * |
| CentOS            | 6       | :red_circle:         |
|                   | 7       | :white_check_mark:   |
|                   | 8       | :red_circle:         |

_* Debian 10 is not listed as officially supported by Pterodactyl yet._

## Using the installation scripts

Using the Pterodactyl Panel installation script:

```bash
bash <(curl -s https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/install-panel.sh)
```

Using the Pterodactyl Daemon installation script:

```bash
bash <(curl -s https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/install-daemon.sh)
```

The script will guide you through the install.

*Note: On some systems, it's required to be already logged in as root before executing the one-line command.*

## Contributing

Feel free to fork the project and send a PR! :smiley:
