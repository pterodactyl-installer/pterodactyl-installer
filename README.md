# :bird: pterodactyl-installer

Scripts for installing Pterodactyl on both Panel & Daemon.

Read more about [Pterodactyl here](https://pterodactyl.io/).

# Supported installations

List of supported installation setups for panel and daemon (installations supported by this installation script).

### Supported panel operating systems and webservers

| Operating System  | Version | nginx support      | Apache support |
| ----------------- | ------- | ------------------ | -------------- |
| Ubuntu            | 16.04   | :white_check_mark: | :red_circle:   |
|                   | 18.04   | :white_check_mark: | :red_circle:   |
| Debian            | 8       | :white_check_mark: | :red_circle:   |
|                   | 9       | :white_check_mark: | :red_circle:   |
| CentOS            | 7       | :white_check_mark: | :red_circle:   |

### Supported daemon operating systems

| Operating System  | Version | Supported          |
| ----------------- | ------- | ------------------ |
| Ubuntu            | 16.04   | :white_check_mark: |
|                   | 18.04   | :white_check_mark: |
| Debian            | 8       | :red_circle:       |
|                   | 9       | :white_check_mark: |
| CentOS            | 6       | :red_circle:       |
|                   | 7       | :white_check_mark: |

# Using the installation scripts

Using the Pterodactyl Panel installation script:

`bash <(curl -s https://raw.githubusercontent.com/MrKaKisen/pterodactyl-installer/master/install-panel.sh)`

Using the Pterodactyl Daemon installation script:

`bash <(curl -s https://raw.githubusercontent.com/MrKaKisen/pterodactyl-installer/master/install-daemon.sh)`

The script will guide you through the install.
