# :bird: pterodactyl-installer

![Test Panel](https://github.com/pterodactyl-installer/pterodactyl-installer/actions/workflows/panel.yml/badge.svg)
![Test Wings](https://github.com/pterodactyl-installer/pterodactyl-installer/actions/workflows/wings.yml/badge.svg)
![Shellcheck](https://github.com/pterodactyl-installer/pterodactyl-installer/actions/workflows/shellcheck.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/github/license/pterodactyl-installer/pterodactyl-installer)](LICENSE)
[![Discord](https://img.shields.io/discord/682342331206074373?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://pterodactyl-installer.se/discord)
[![made-with-bash](https://img.shields.io/badge/-Made%20with%20Bash-1f425f.svg?logo=image%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw%2FeHBhY2tldCBiZWdpbj0i77u%2FIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8%2BIDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTExIDc5LjE1ODMyNSwgMjAxNS8wOS8xMC0wMToxMDoyMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkE3MDg2QTAyQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkE3MDg2QTAzQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QTcwODZBMDBBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6QTcwODZBMDFBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciLz4gPC9yZGY6RGVzY3JpcHRpb24%2BIDwvcmRmOlJERj4gPC94OnhtcG1ldGE%2BIDw%2FeHBhY2tldCBlbmQ9InIiPz6lm45hAAADkklEQVR42qyVa0yTVxzGn7d9Wy03MS2ii8s%2BeokYNQSVhCzOjXZOFNF4jx%2BMRmPUMEUEqVG36jo2thizLSQSMd4N8ZoQ8RKjJtooaCpK6ZoCtRXKpRempbTv5ey83bhkAUphz8fznvP8znn%2B%2F3NeEEJgNBoRRSmz0ub%2FfuxEacBg%2FDmYtiCjgo5NG2mBXq%2BH5I1ogMRk9Zbd%2BQU2e1ML6VPLOyf5tvBQ8yT1lG10imxsABm7SLs898GTpyYynEzP60hO3trHDKvMigUwdeaceacqzp7nOI4n0SSIIjl36ao4Z356OV07fSQAk6xJ3XGg%2BLCr1d1OYlVHp4eUHPnerU79ZA%2F1kuv1JQMAg%2BE4O2P23EumF3VkvHprsZKMzKwbRUXFEyTvSIEmTVbrysp%2BWr8wfQHGK6WChVa3bKUmdWou%2BjpArdGkzZ41c1zG%2Fu5uGH4swzd561F%2BuhIT4%2BLnSuPsv9%2BJKIpjNr9dXYOyk7%2FBZrcjIT4eCnoKgedJP4BEqhG77E3NKP31FO7cfQA5K0dSYuLgz2TwCWJSOBzG6crzKK%2BohNfni%2Bx6OMUMMNe%2Fgf7ocbw0v0acKg6J8Ql0q%2BT%2FAXR5PNi5dz9c71upuQqCKFAD%2BYhrZLEAmpodaHO3Qy6TI3NhBpbrshGtOWKOSMYwYGQM8nJzoFJNxP2HjyIQho4PewK6hBktoDcUwtIln4PjOWzflQ%2Be5yl0yCCYgYikTclGlxadio%2BBQCSiW1UXoVGrKYwH4RgMrjU1HAB4vR6LzWYfFUCKxfS8Ftk5qxHoCUQAUkRJaSEokkV6Y%2F%2BJUOC4hn6A39NVXVBYeNP8piH6HeA4fPbpdBQV5KOx0QaL1YppX3Jgk0TwH2Vg6S3u%2BdB91%2B%2FpuNYPYFl5uP5V7ZqvsrX7jxqMXR6ff3gCQSTzFI0a1TX3wIs8ul%2Bq4HuWAAiM39vhOuR1O1fQ2gT%2F26Z8Z5vrl2OHi9OXZn995nLV9aFfS6UC9JeJPfuK0NBohWpCHMSAAsFe74WWP%2BvT25wtP9Bpob6uGqqyDnOtaeumjRu%2ByFu36VntK%2FPA5umTJeUtPWZSU9BCgud661odVp3DZtkc7AnYR33RRC708PrVi1larW7XwZIjLnd7R6SgSqWSNjU1B3F72pz5TZbXmX5vV81Yb7Lg7XT%2FUXriu8XLVqw6c6XqWnBKiiYU%2BMt3wWF7u7i91XlSEITwSAZ%2FCzAAHsJVbwXYFFEAAAAASUVORK5CYII%3D)](https://www.gnu.org/software/bash/)

非官方安装脚本 Pterodactyl Panel & Wings. 请注意该脚本采用Pterodactyl®的中文汉化并国内本土化版

阅读更多关于 jexactyl 这里 该脚本与官方 Pterodactyl Project 或 linke131 无关.

## 特征

- 自动安装 Jexactyl 面板（依赖项、数据库、cronjob、nginx） - 自动安装 Pterodactyl Wings（Docker、systemd - 面板：（可选）Let's Encrypt 自动配置 - 面板：（可选）防火墙自动配置.

## 帮助和支持

如需有关脚本本身以及**非官方 Pterodactyl 项目**的帮助和支持，您可以创建一个问题 [Github issues](https://github.com/linkea131/jexactyl-installer/issues).

## panel 支持的操作系统

panel 和 Wings 支持的安装设置列表（此安装脚本支持的操作系统及Nginx And PHP）.

### 支持的面板和机翼操作系统

| 操作系统 | 版本 | 支持          | PHP 版本 |
| ---------------- | ------- | ------------------ | ----------- |
| Ubuntu           | 14.04   | :red_circle:       |             |
|                  | 16.04   | :red_circle: \*    |             |
|                  | 18.04   | :red_circle: \*    | 8.1         |
|                  | 20.04   | :white_check_mark: | 8.1         |
|                  | 22.04   | :white_check_mark: | 8.1         |
| Debian           | 8       | :red_circle: \*    |             |
|                  | 9       | :red_circle: \*    |             |
|                  | 10      | :white_check_mark: | 8.1         |
|                  | 11      | :white_check_mark: | 8.1         |
|                  | 12      | :white_check_mark: | 8.1         |
| CentOS           | 6       | :red_circle:       |             |
|                  | 7       | :red_circle: \*    |             |
|                  | 8       | :red_circle: \*    |             |
| Rocky Linux      | 8       | :white_check_mark: | 8.1         |
|                  | 9       | :white_check_mark: | 8.1         |
| AlmaLinux        | 8       | :white_check_mark: | 8.1         |
|                  | 9       | :white_check_mark: | 8.1         |

_\* 表示此脚本以前支持的操作系统和版本._

## 使用安装脚本

要使用安装脚本, 只需以 root 身份运行此命令即可, 该脚本将询问您是否要仅安装面板、仅安装 Wings 还是两者都安装.

```bash
bash <(curl -s https://raw.githubusercontent.com/linke131/jexactyl-installer/v1.11.3.3/install.sh)
```
## 上面执行失败可尝试以下方法
```
wget https://raw.githubusercontent.com/linke131/pterodactyl-installer/master/install.sh
```

## 然后安装
```
bash install.sh
```

_注意: 在某些系统上, 在执行一行命令之前需要先以 root 身份登录（其中命令前面的“sudo”不起作用）._


## 防火墙设置

安装脚本可以为您安装和配置防火墙. 该脚本将询问您是否需要此操作. 强烈建议选择自动防火墙设置.

## 发布 & 操作

### 在本地测试脚本

为了测试脚本，我们使用 [Vagrant](https://www.vagrantup.com). 使用 Vagrant，您可以快速启动并运行一台新机器来测试脚本.

如果您想一次性在所有受支持的安装上测试该脚本，只需运行以下命令.

```bash
vagrant up
```

如果您只想测试特定发行版, 可以运行以下命令.

```bash
vagrant up <name>
```

将名称替换为以下内容之一 (支持的操作系统).

- `ubuntu_jammy`
- `ubuntu_focal`
- `debian_bullseye`
- `debian_buster`
- `debian_bookworm`
- `almalinux_8`
- `almalinux_9`
- `rockylinux_8`
- `rockylinux_9`

然后你可以使用 `vagrant ssh <机器名称>` 使用 SSH 连接到服务器. 项目目录将被挂载在 `/vagrant` 因此您可以在本地快速修改脚本，然后通过运行脚本来测试更改 `/vagrant/install_panel.sh` 和 `/vagrant/install_wings.sh` 分别.

### 创建正式版本

每次发布提交都应该更改几个文件，首先更新 `CHANGELOG.md` 以便同时显示发布日期和发布标签. 不应对变更日志点本身进行任何更改, 其次更新 `GITHUB_SOURCE` 和 `SCRIPT_RELEASE` 同时 `install-panel.sh` 和 `install-wings.sh`. 第三步, 更新 `SCRIPT_RELEASE` in `install.sh`. 最后，您现在可以使用消息推送提交`Release vX.Y.Z`. 在 GitHub 上创建一个版本 [此次提交](https://github.com/vilhelmprytz/pterodactyl-installer/commit/90aaae10785f1032fdf90b216a4a8d8ca64e6d44) 以供参考.

发布版本后推送另一个提交, 该提交将撤销您所做的更改 `install-wings.sh` 和 `install-panel.sh`. 查看 [此次提交](https://github.com/vilhelmprytz/pterodactyl-installer/commit/be5f361523d1d546d49eef8b3ce1a9145eded234) 以供参考.

## 贡献者 ✨

Copyright (C) 2018 - 2023, Vilhelm Prytz, <xwei58148v5871314@gmail.com>

创建和维护者 [Vilhelm Prytz](https://github.com/vilhelmprytz).

感谢 Discord 版主 [sam1370](https://github.com/sam1370), [Linux123123](https://github.com/Linux123123) 和 [sinjs](https://github.com/sinjs) 在 Discord 服务器上提供帮助!

并特别感谢 [Linux123123](https://github.com/Linux123123) 经常通过错误报告、功能请求、拉取请求等为项目做出贡献!
