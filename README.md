# :bird: pterodactyl-installer

[![Build Status](https://travis-ci.com/VilhelmPrytz/pterodactyl-installer.svg?branch=master)](https://travis-ci.com/VilhelmPrytz/pterodactyl-installer)
[![License: GPL v3](https://img.shields.io/github/license/VilhelmPrytz/pterodactyl-installer)](LICENSE)
[![Discord](https://img.shields.io/discord/682342331206074373?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/2zMdudJ)
[![made-with-bash](https://img.shields.io/badge/-Made%20with%20Bash-1f425f.svg?logo=image%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw%2FeHBhY2tldCBiZWdpbj0i77u%2FIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8%2BIDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTExIDc5LjE1ODMyNSwgMjAxNS8wOS8xMC0wMToxMDoyMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkE3MDg2QTAyQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkE3MDg2QTAzQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QTcwODZBMDBBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6QTcwODZBMDFBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciLz4gPC9yZGY6RGVzY3JpcHRpb24%2BIDwvcmRmOlJERj4gPC94OnhtcG1ldGE%2BIDw%2FeHBhY2tldCBlbmQ9InIiPz6lm45hAAADkklEQVR42qyVa0yTVxzGn7d9Wy03MS2ii8s%2BeokYNQSVhCzOjXZOFNF4jx%2BMRmPUMEUEqVG36jo2thizLSQSMd4N8ZoQ8RKjJtooaCpK6ZoCtRXKpRempbTv5ey83bhkAUphz8fznvP8znn%2B%2F3NeEEJgNBoRRSmz0ub%2FfuxEacBg%2FDmYtiCjgo5NG2mBXq%2BH5I1ogMRk9Zbd%2BQU2e1ML6VPLOyf5tvBQ8yT1lG10imxsABm7SLs898GTpyYynEzP60hO3trHDKvMigUwdeaceacqzp7nOI4n0SSIIjl36ao4Z356OV07fSQAk6xJ3XGg%2BLCr1d1OYlVHp4eUHPnerU79ZA%2F1kuv1JQMAg%2BE4O2P23EumF3VkvHprsZKMzKwbRUXFEyTvSIEmTVbrysp%2BWr8wfQHGK6WChVa3bKUmdWou%2BjpArdGkzZ41c1zG%2Fu5uGH4swzd561F%2BuhIT4%2BLnSuPsv9%2BJKIpjNr9dXYOyk7%2FBZrcjIT4eCnoKgedJP4BEqhG77E3NKP31FO7cfQA5K0dSYuLgz2TwCWJSOBzG6crzKK%2BohNfni%2Bx6OMUMMNe%2Fgf7ocbw0v0acKg6J8Ql0q%2BT%2FAXR5PNi5dz9c71upuQqCKFAD%2BYhrZLEAmpodaHO3Qy6TI3NhBpbrshGtOWKOSMYwYGQM8nJzoFJNxP2HjyIQho4PewK6hBktoDcUwtIln4PjOWzflQ%2Be5yl0yCCYgYikTclGlxadio%2BBQCSiW1UXoVGrKYwH4RgMrjU1HAB4vR6LzWYfFUCKxfS8Ftk5qxHoCUQAUkRJaSEokkV6Y%2F%2BJUOC4hn6A39NVXVBYeNP8piH6HeA4fPbpdBQV5KOx0QaL1YppX3Jgk0TwH2Vg6S3u%2BdB91%2B%2FpuNYPYFl5uP5V7ZqvsrX7jxqMXR6ff3gCQSTzFI0a1TX3wIs8ul%2Bq4HuWAAiM39vhOuR1O1fQ2gT%2F26Z8Z5vrl2OHi9OXZn995nLV9aFfS6UC9JeJPfuK0NBohWpCHMSAAsFe74WWP%2BvT25wtP9Bpob6uGqqyDnOtaeumjRu%2ByFu36VntK%2FPA5umTJeUtPWZSU9BCgud661odVp3DZtkc7AnYR33RRC708PrVi1larW7XwZIjLnd7R6SgSqWSNjU1B3F72pz5TZbXmX5vV81Yb7Lg7XT%2FUXriu8XLVqw6c6XqWnBKiiYU%2BMt3wWF7u7i91XlSEITwSAZ%2FCzAAHsJVbwXYFFEAAAAASUVORK5CYII%3D)](https://www.gnu.org/software/bash/)

Unofficial scripts for installing Pterodactyl on both Panel & Daemon.

Read more about [Pterodactyl](https://pterodactyl.io/) here. This script is not associated with the official Pterodactyl Project.

This project is available at [GitHub](https://github.com/VilhelmPrytz/pterodactyl-installer) with read-only forks available at [GitLab](https://gitlab.com/vilhelm/pterodactyl-installer) and [Bitbucket](https://bitbucket.org/prytz/pterodactyl-installer/src/master/).

## Features

- Automatic installation of the Pterodactyl panel (dependencies,  database, cronjob, nginx).
- Automatic installation of the Pterodactyl daemon (Docker, NodeJS, systemd).
- Panel: (optional) automatic configuration of Let's Encrypt.
- Panel: (optional) automatic configuration of UFW (firewall for Ubuntu/Debian).

## Help and support

For help and support regarding the script itself and **not the official Pterodactyl project itself**, you can join the [Discord Chat](https://discord.gg/2zMdudJ).

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
|                   | 10      | :white_check_mark:   |
| CentOS            | 6       | :red_circle:         |
|                   | 7       | :white_check_mark:   |
|                   | 8       | :white_check_mark:   |

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

The script can automatically open the ports for SSH (22), HTTP (80) and HTTPS (443). The installer script should ask whether you'd like it to configure UFW automatically or not.

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

## Contributors ✨

Created and maintained by [Vilhelm Prytz](https://github.com/VilhelmPrytz).

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://vilhelmprytz.se"><img src="https://avatars2.githubusercontent.com/u/15460993?v=4" width="100px;" alt=""/><br /><sub><b>Vilhelm Prytz</b></sub></a><br /><a href="https://github.com/VilhelmPrytz/pterodactyl-installer/commits?author=VilhelmPrytz" title="Code">💻</a> <a href="https://github.com/VilhelmPrytz/pterodactyl-installer/issues?q=author%3AVilhelmPrytz" title="Bug reports">🐛</a> <a href="https://github.com/VilhelmPrytz/pterodactyl-installer/commits?author=VilhelmPrytz" title="Documentation">📖</a> <a href="#projectManagement-VilhelmPrytz" title="Project Management">📆</a> <a href="#question-VilhelmPrytz" title="Answering Questions">💬</a></td>
    <td align="center"><a href="https://github.com/MrFlacko"><img src="https://avatars0.githubusercontent.com/u/35322515?v=4" width="100px;" alt=""/><br /><sub><b>MrFlacko</b></sub></a><br /><a href="https://github.com/VilhelmPrytz/pterodactyl-installer/commits?author=MrFlacko" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Iomega0318"><img src="https://avatars2.githubusercontent.com/u/5641516?v=4" width="100px;" alt=""/><br /><sub><b>Iomega0318</b></sub></a><br /><a href="https://github.com/VilhelmPrytz/pterodactyl-installer/commits?author=Iomega0318" title="Code">💻</a></td>
    <td align="center"><a href="https://creepercreep.fr"><img src="https://avatars3.githubusercontent.com/u/39345534?v=4" width="100px;" alt=""/><br /><sub><b>Tristan</b></sub></a><br /><a href="https://github.com/VilhelmPrytz/pterodactyl-installer/commits?author=MichelBaie" title="Code">💻</a> <a href="https://github.com/VilhelmPrytz/pterodactyl-installer/issues?q=author%3AMichelBaie" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://hoerli.net"><img src="https://avatars3.githubusercontent.com/u/13108516?v=4" width="100px;" alt=""/><br /><sub><b>Hoerli</b></sub></a><br /><a href="https://github.com/VilhelmPrytz/pterodactyl-installer/issues?q=author%3AHoerli1337" title="Bug reports">🐛</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
