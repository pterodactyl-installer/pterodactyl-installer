# Changelog

This project follows the [semantic versioning](https://semver.org) convention. Changelog points should be divided into fixed, changed, or added.

## v1.1.1 (released on 2024-11-15)
### Fixed
- [#514](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/514) panel: Update PHP from 8.1 to 8.3 (thanks [@SuperEvilLuke](https://github.com/SuperEvilLuke) for contributing!)
- [#502](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/502) panel/wings: Added more checks and more verbose logging to uninstallation script. (thanks [QXIoa](https://github.com/QXIoa) for contributing!)

## v1.1.0 (released on 2024-07-10)

### Fixed

- [#451](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/451) all: Update copyright year to 2024 (thanks [@BeastGamer81](https://github.com/BeastGamer81) for contributing!).
- [#452](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/452) panel/wings: Replace mysql commands with mariadb
- [#480](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/480) panel: update default pteroq.service file

### Added

- [#467](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/467) panel/wings: add support for Ubuntu 24.04

## v1.0.0 (released on 2023-07-31)

### Added

- [#416](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/416) panel/wings: add support for Debian 12 (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.12.3 (released on 2023-02-18)

### Fixed

- [#385](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/385) lib: Fix a bug that would cause the script to fail on some systems because missing paths in $PATH (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).
- [#392](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/392) lib: Add back missing function `print_list` used in uninstall script (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.12.2 (released on 2022-12-18)

### Fixed

- [#366](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/366) panel/lib/wings Fix ask_database_external, some shellcheck issues, broken support for Alma Linux and Rocky Linux (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).
- [#377](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/377) wings: Fix wings script calling wrong firewall function (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.12.1 (released on 2022-12-01)

### Fixed

- [#359](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/359) lib: Fix a bug that would cause the script to fail on some systems because `curl` was not able to overwrite existing `/tmp/lib.sh`.

## v0.12.0 (released on 2022-12-01)

- [#353](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/353) panel: Update php version to 8.1 (thanks to [@drylian](https://github.com/drylian) for contributing!).
- [#315](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/315) panel/wings: Split the scripts into separate components, UI functions and installation functions. This is a major overhaul, expect bugs! (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).
- [#283](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/283) panel/wings: Introduce support for Rocky Linux and AlmaLinux, also remove support for CentOS and Debian 9 (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.11.0 (released on 2022-05-17)

### Added

- [#322](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/322) panel/wings: Added support for Ubuntu 22.04.

### Fixed

- [#262](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/262) wings: Fix a bug that would cause the script to fail because /usr/sbin missing in $PATH when the script tries to run virt-what (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.10.0 (released on 2022-03-14)

### Added

- [#300](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/300) panel: Check if FQDN is IP and skip asking for Let's Encrypt certificate if FQDN is IP (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

### Fixed

- [#285](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/285) panel: Fix Nginx configuration files so that Nginx listens to IPv6 as well by default.

### Changed

- [#267](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/267) wings: Rewrite some of the database host functionality to work with remote MySQL clients (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).
- [#288](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/288) wings: Avoid usage of deprecated apt-key during Docker installation.
- [#289](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/289) Replace old references to "daemon" with Wings.

## v0.9.0 (released on 2021-12-05)

### Added

- [#249](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/249) install: Automatically log installation process to `/var/log/pterodactyl-installer.log` (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

### Fixed

- [#229](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/229) wings: Fixed a bug that would cause the process of obtaining a Let's Encrypt certificate to fail on CentOS 7 and CentOS 8 due to the missing `epel-release` package (thanks [@Linux123123](https://github.com/Linux123123) for reporting!).
- [#264](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/264) install: Fix incorrectly labeled setup option (thanks [@NoahvdAa](https://github.com/NoahvdAa) for contributing!).
- [#266](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/266) panel/wings: Usage of hyphens in database names/usernames is not supported by the script. The script now checks if the credentials provided by the user contain a hyphen (thanks [@GoudronViande24](https://github.com/GoudronViande24) for reporting!).

## v0.8.1 (released on 2021-08-28)

### Fixed

- [#238](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/238) panel: Fixed a bug that would cause the installation script to fail on CentOS 8 because of invalid reference to `mariadb-secure-installation`.

## v0.8.0 (released on 2021-08-28)

### Added

- [#220](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/220) wings: Add a feature that lets the user automatically create a user for "database host" (thanks [@sinjs](https://github.com/sinjs) for contributing!).
- [#230](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/230) panel/wings: Added support for Debian 11 (bullseye) (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.7.1 (released on 2021-07-31)

### Fixed

- [#217](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/217) panel: Fixed a bug that would cause the panel installation to fail on CentOS since the symlink `mysql_secure_installation` is gone (thanks [@aa-abert](https://github.com/aa-abert) for contributing!).

## v0.7.0 (released on 2021-07-16)

### Fixed

- [#193](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/193) lib/verify-fqdn: Fixed a minor typo, the word "Encrypt" was misspelled and is now fixed (thanks to [@Hey](https://github.com/Hey) for contributing!).
- [#201](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/201) lib/verify-fqdn: Fixed so that CNAME records work as FQDN and are properly detected by the script (thanks to [@jobhh](https://github.com/jobhh) for contributing!).
- [#200](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/200) wings: Fixed a bug that would cause the script to not detect unsupported virtualization (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

### Added

- [#81](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/81) wings: Added a feature that automatically skips the MariaDB question if MySQL/MariaDB is detected.
- [#204](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/204) wings: Added support for arm64 (thanks to [@puiemonta1234](https://github.com/puiemonta1234) for contributing!).

## v0.6.0 (released on 2021-05-21)

### Fixed

- [#186](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/186) panel: Fixed a bug that would cause the script to exit if the script tried to create a symbolic link twice (thanks [@Linux123123](https://github.com/Linux123123) for reporting and contributing!).

### Added

- [#157](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/157) panel/wings: Added email validation. Emails are now validated using a regex before accepted as values (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.5.0 (released on 2021-05-15)

### Fixed

- [#158](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/158) panel: Fixed a bug that would let users run the panel script on other CPU architectures than `x86_64`, script now prints a warning if the user is using anything but `x86_64` (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).
- [#176](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/176) wings: Fixed a broken link to the official documentation (thanks to [@sinmineryt](https://github.com/sinmineryt) for contributing!).

### Changed

- [#160](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/160) wings: Unsupported virtualization types no longer forcefully quit the script. An option to override the check has been added.

## v0.4.0 (released on 2021-03-16)

### Changed

- [#168](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/168) panel: Use PHP version 8.0 over 7.4 for all supported installations (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.3.0 (released on 2021-02-24)

### Fixed

- [#151](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/151) panel: `APP_ENVIRONMENT_ONLY` was set to `true` when it should be `false`. This caused the panel to prohibit modifying the settings from the web interface, which is not intended behavior.
- [#165](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/165) panel: Fix so that the `pteroq` service uses the correct user on CentOS (thanks [@PipeItToDevNull](https://github.com/PipeItToDevNull) for reporting!).

### Changed

- [#129](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/129) wings: Clarify how to connect new Wings installation with the panel (using auto deploy).
- [#153](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/153) panel/wings: Changed so that the script will no longer tell you to open firewall ports if you have enabled automatic firewall configuration.
- [#153](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/153) panel: Remove deprecated third-party suggestions.

### Added

- [#148](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/148) wings: Added so that the Wings installation script will now verify FQDN using `lib/verify-fqdn` if the user chooses to configure Let's Encrypt automatically.

## v0.2.0 (released on 2021-01-18)

### Fixed

- [#113](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/113) panel: Fixed a bug that would cause the script to exit due to failing to create a "bus connection". Related to [#115](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/115) as well.
- [#135](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/135) panel/wings: Fixed so that the automatic ufw firewall configuration no longer requires confirming for the enable operation (user interaction after initial configuration is not intended behavior).

### Changed

- [#88](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/88) panel: Changed so that certbot now uses `certbot --nginx` over `certbot certonly` which makes it easier to perform certificate renewals later on (thanks [@Linux123123](https://github.com/Linux123123)).
- [#100](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/100) panel: Refactor several different functions in panel script, removal of redundant variables and functions and general cleanup/restructure (thanks [@Linux123123](https://github.com/Linux123123)).
- [#115](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/115) panel: Refactor timezone validation.
- [#137](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/137) panel: Removed ability to run `p:environment:mail` script since it's redundant.
- [#139](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/139) wings: Refactor - replaced all `"$var"` with `[ "$var" == true ]` (thanks [@Linux123123](https://github.com/Linux123123)).

### Added

- [098d01a](https://github.com/pterodactyl-installer/pterodactyl-installer/commit/098d01a9729dffaf40e80077da2d7d51b42a197b) panel: Add a prompt in `verify-fqdn` that requires user consent before performing HTTPS request against [https://checkip.pterodactyl-installer.se](https://checkip.pterodactyl-installer.se).
- [#78](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/78) panel: Add option to auto-generate MySQL passwords and remember them throughout the installation.

## v0.1.1 (released on 2021-01-01)

### Fixed

- [#133](https://github.com/pterodactyl-installer/pterodactyl-installer/issues/133) panel: Fixed the `verify-fqdn.sh` so that it now installs the packages quietly. Panel script will now only execute the FQDN verification if `ASSUME_SSL` or `CONFIGURE_LETSENCRYPT` is true.

## v0.1.0 (released on 2021-01-01)

- Initial release, introduces versioning to the project
