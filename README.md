# :bird: pterodactyl-installer

[![Build Status](https://travis-ci.com/vilhelmprytz/pterodactyl-installer.svg?branch=master)](https://travis-ci.com/vilhelmprytz/pterodactyl-installer)
[![License: GPL v3](https://img.shields.io/github/license/vilhelmprytz/pterodactyl-installer)](LICENSE)
[![Discord](https://img.shields.io/discord/682342331206074373?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://pterodactyl-installer.se/discord)
[![made-with-bash](https://img.shields.io/badge/-Made%20with%20Bash-1f425f.svg?logo=image%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw%2FeHBhY2tldCBiZWdpbj0i77u%2FIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8%2BIDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTExIDc5LjE1ODMyNSwgMjAxNS8wOS8xMC0wMToxMDoyMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkE3MDg2QTAyQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkE3MDg2QTAzQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QTcwODZBMDBBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6QTcwODZBMDFBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciLz4gPC9yZGY6RGVzY3JpcHRpb24%2BIDwvcmRmOlJERj4gPC94OnhtcG1ldGE%2BIDw%2FeHBhY2tldCBlbmQ9InIiPz6lm45hAAADkklEQVR42qyVa0yTVxzGn7d9Wy03MS2ii8s%2BeokYNQSVhCzOjXZOFNF4jx%2BMRmPUMEUEqVG36jo2thizLSQSMd4N8ZoQ8RKjJtooaCpK6ZoCtRXKpRempbTv5ey83bhkAUphz8fznvP8znn%2B%2F3NeEEJgNBoRRSmz0ub%2FfuxEacBg%2FDmYtiCjgo5NG2mBXq%2BH5I1ogMRk9Zbd%2BQU2e1ML6VPLOyf5tvBQ8yT1lG10imxsABm7SLs898GTpyYynEzP60hO3trHDKvMigUwdeaceacqzp7nOI4n0SSIIjl36ao4Z356OV07fSQAk6xJ3XGg%2BLCr1d1OYlVHp4eUHPnerU79ZA%2F1kuv1JQMAg%2BE4O2P23EumF3VkvHprsZKMzKwbRUXFEyTvSIEmTVbrysp%2BWr8wfQHGK6WChVa3bKUmdWou%2BjpArdGkzZ41c1zG%2Fu5uGH4swzd561F%2BuhIT4%2BLnSuPsv9%2BJKIpjNr9dXYOyk7%2FBZrcjIT4eCnoKgedJP4BEqhG77E3NKP31FO7cfQA5K0dSYuLgz2TwCWJSOBzG6crzKK%2BohNfni%2Bx6OMUMMNe%2Fgf7ocbw0v0acKg6J8Ql0q%2BT%2FAXR5PNi5dz9c71upuQqCKFAD%2BYhrZLEAmpodaHO3Qy6TI3NhBpbrshGtOWKOSMYwYGQM8nJzoFJNxP2HjyIQho4PewK6hBktoDcUwtIln4PjOWzflQ%2Be5yl0yCCYgYikTclGlxadio%2BBQCSiW1UXoVGrKYwH4RgMrjU1HAB4vR6LzWYfFUCKxfS8Ftk5qxHoCUQAUkRJaSEokkV6Y%2F%2BJUOC4hn6A39NVXVBYeNP8piH6HeA4fPbpdBQV5KOx0QaL1YppX3Jgk0TwH2Vg6S3u%2BdB91%2B%2FpuNYPYFl5uP5V7ZqvsrX7jxqMXR6ff3gCQSTzFI0a1TX3wIs8ul%2Bq4HuWAAiM39vhOuR1O1fQ2gT%2F26Z8Z5vrl2OHi9OXZn995nLV9aFfS6UC9JeJPfuK0NBohWpCHMSAAsFe74WWP%2BvT25wtP9Bpob6uGqqyDnOtaeumjRu%2ByFu36VntK%2FPA5umTJeUtPWZSU9BCgud661odVp3DZtkc7AnYR33RRC708PrVi1larW7XwZIjLnd7R6SgSqWSNjU1B3F72pz5TZbXmX5vV81Yb7Lg7XT%2FUXriu8XLVqw6c6XqWnBKiiYU%2BMt3wWF7u7i91XlSEITwSAZ%2FCzAAHsJVbwXYFFEAAAAASUVORK5CYII%3D)](https://www.gnu.org/software/bash/)

Unofficial scripts for installing Pterodactyl Panel & Wings. Works with the latest version of Pterodactyl!

Read more about [Pterodactyl](https://pterodactyl.io/) here. This script is not associated with the official Pterodactyl Project.

## Features

- Automatic installation of the Pterodactyl Panel (dependencies, database, cronjob, nginx).
- Automatic installation of the Pterodactyl Wings (Docker, systemd).
- Panel: (optional) automatic configuration of Let's Encrypt.
- Panel: (optional) automatic configuration of UFW (firewall for Ubuntu/Debian).

## Help and support

For help and support regarding the script itself and **not the official Pterodactyl project**, you can join the [Discord Chat](https://pterodactyl-installer.se/discord).

## Supported installations

List of supported installation setups for panel and Wings (installations supported by this installation script).

### Supported panel operating systems and webservers

| Operating System | Version | nginx support      | PHP Version |
| ---------------- | ------- | ------------------ | ----------- |
| Ubuntu           | 14.04   | :red_circle:       |             |
|                  | 16.04   | :red_circle: \*    |             |
|                  | 18.04   | :white_check_mark: | 8.0         |
|                  | 20.04   | :white_check_mark: | 8.0         |
| Debian           | 8       | :red_circle: \*    |             |
|                  | 9       | :white_check_mark: | 8.0         |
|                  | 10      | :white_check_mark: | 8.0         |
| CentOS           | 6       | :red_circle:       |             |
|                  | 7       | :white_check_mark: | 8.0         |
|                  | 8       | :white_check_mark: | 8.0         |

### Supported Wings operating systems

| Operating System | Version | Supported          |
| ---------------- | ------- | ------------------ |
| Ubuntu           | 14.04   | :red_circle:       |
|                  | 16.04   | :red_circle: \*    |
|                  | 18.04   | :white_check_mark: |
|                  | 20.04   | :white_check_mark: |
| Debian           | 8       | :red_circle:       |
|                  | 9       | :white_check_mark: |
|                  | 10      | :white_check_mark: |
| CentOS           | 6       | :red_circle:       |
|                  | 7       | :white_check_mark: |
|                  | 8       | :white_check_mark: |

_\* Ubuntu 16 and Debian 8 no longer supported since Pterodactyl does not actively support it._

## This script has been edited to download the latest version of pterodactyl (1.5.1) along with a simple but relatively nice theme.

## Some images of the theme:
![dracula1](https://user-images.githubusercontent.com/69549678/129277566-feef6f68-df47-4c2c-9aa5-c6fb7fcdffe1.png)
![dracula2](https://user-images.githubusercontent.com/69549678/129277583-3036fe7d-d166-410e-928d-4d55ef7d3681.png)


## Using the installation scripts

To use the install scripts, just run the commands as root.

Panel Installation:
```bash
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/pterodactyl-installer/master/install-panel.sh)
```
After your panel is installed, you will likely get "500 SERVER ERROR"
Don't despair, run this command, wait for it to finish, and everything will be working.
```bash
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/pterodactyl-installer/master/yarn-production.sh)
```
Wings Installation:
```bash
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/pterodactyl-installer/master/install-wings.sh)
```

## Additional information:
This is a fork of the official script.

Use this modified script only if you want a dashboard with a different theme.

This modification does not change the default installation of the wings of the official script, therefore, it can be used safely.

_Note: On some systems, it's required to be already logged in as root before executing the one-line command (where `sudo` is in front of the command does not work)._

Here is a [YouTube video](https://www.youtube.com/watch?v=E8UJhyUFoHM) that illustrates the installation process.

## Firewall setup

The installation scripts can install and configure a firewall for you. The script will ask whether you want this or not. It is highly recommended to opt-in for the automatic firewall setup.

## Development & Ops

## Contributors ✨

Copyright (C) 2018 - 2021, Vilhelm Prytz, <vilhelm@prytznet.se>

Created and maintained by [Vilhelm Prytz](https://github.com/vilhelmprytz).

Special thanks to the Discord moderators [sam1370](https://github.com/sam1370), [Linux123123](https://github.com/Linux123123) and [sinmineryt](https://github.com/sinmineryt) for helping on the Discord server!
