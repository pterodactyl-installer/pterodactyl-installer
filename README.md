# :bird: pterodactyl-installer

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/602a6ae000974d17a16d26b50377cf86)](https://app.codacy.com/manual/VilhelmPrytz_2/pterodactyl-installer?utm_source=github.com&utm_medium=referral&utm_content=VilhelmPrytz/pterodactyl-installer&utm_campaign=Badge_Grade_Settings)
[![Build Status](https://travis-ci.com/VilhelmPrytz/pterodactyl-installer.svg?branch=master)](https://travis-ci.com/VilhelmPrytz/pterodactyl-installer)
[![License: GPL v3](https://img.shields.io/github/license/VilhelmPrytz/pterodactyl-installer)](LICENSE)

Unofficial scripts for installing Pterodactyl on both Panel & Daemon.

Read more about [Pterodactyl](https://pterodactyl.io/) here. This script is not associated with the official Pterodactyl Project.

This project is available at [GitHub](https://github.com/VilhelmPrytz/pterodactyl-installer) with read-only forks available at [GitLab](https://gitlab.com/vilhelm/pterodactyl-installer) and [Bitbucket](https://bitbucket.org/prytz/pterodactyl-installer/src/master/).

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
|                   | 8       | :white_check_mark:   |

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

## Firewall setup

The installation scripts do not configure your firewall automatically.

### Debian/Ubuntu

On Debian and Ubuntu, `ufw` can be used. Install it using `apt`.

```bash
apt install -y ufw
```

#### Panel

Allow HTTP/HTTPS connections for panel installation.

```bash
ufw allow http
ufw allow https
```

#### Daemon

Allow 8080 and 2022.

```bash
ufw allow 8080
ufw allow 2022
```

#### Enable the firewall

Make sure to also enable SSH (or allow SSH from your IP only, depending on your setup).

```bash
ufw allow ssh
```

Enable the firewall.

```bash
ufw enable
```

### CentOS

On CentOS, `firewall-cmd` can be used.

#### Panel

Allow HTTP and HTTPS.

```bash
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
```

#### Daemon

Allow 8080 and 2022.

```bash
firewall-cmd --add-port 8080/tcp --permanent
firewall-cmd --add-port 2022/tcp --permanent
firewall-cmd --permanent --zone=trusted --change-interface=docker0
```

#### Enable the firewall

Reload the firewall to enable the changes.

```bash
firewall-cmd --reload
```

## Contributing

Feel free to fork the project and send a PR! :smiley:
