# Changelog

This project follows the [semantic versioning](https://semver.org) convention. Changelog points should be divided into fixed, changed, or added.

## v0.7.0 (released on 2021-07-16)

### Fixed

- [#193](https://github.com/vilhelmprytz/pterodactyl-installer/issues/193) lib/verify-fqdn: Fixed a minor typo, the word "Encrypt" was misspelled and is now fixed (thanks to [@Hey](https://github.com/Hey) for contributing!).
- [#201](https://github.com/vilhelmprytz/pterodactyl-installer/issues/201) lib/verify-fqdn: Fixed so that CNAME records work as FQDN and are properly detected by the script (thanks to [@jobhh](https://github.com/jobhh) for contributing!).
- [#200](https://github.com/vilhelmprytz/pterodactyl-installer/issues/200) wings: Fixed a bug that would cause the script to not detect unsupported virtualization (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

### Added

- [#81](https://github.com/vilhelmprytz/pterodactyl-installer/issues/81) wings: Added a feature that automatically skips the MariaDB question if MySQL/MariaDB is detected.
- [#204](https://github.com/vilhelmprytz/pterodactyl-installer/issues/204) wings: Added support for arm64 (thanks to [@puiemonta1234](https://github.com/puiemonta1234) for contributing!).

## v0.6.0 (released on 2021-05-21)

### Fixed

- [#186](https://github.com/vilhelmprytz/pterodactyl-installer/issues/186) panel: Fixed a bug that would cause the script to exit if the script tried to create a symbolic link twice (thanks [@Linux123123](https://github.com/Linux123123) for reporting and contributing!).

### Added

- [#157](https://github.com/vilhelmprytz/pterodactyl-installer/issues/157) panel/wings: Added email validation. Emails are now validated using a regex before accepted as values (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.5.0 (released on 2021-05-15)

### Fixed

- [#158](https://github.com/vilhelmprytz/pterodactyl-installer/issues/158) panel: Fixed a bug that would let users run the panel script on other CPU architectures than `x86_64`, script now prints a warning if the user is using anything but `x86_64` (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).
- [#176](https://github.com/vilhelmprytz/pterodactyl-installer/pull/176) wings: Fixed a broken link to the official documentation (thanks to [@sinmineryt](https://github.com/sinmineryt) for contributing!).

### Changed

- [#160](https://github.com/vilhelmprytz/pterodactyl-installer/issues/160) wings: Unsupported virtualization types no longer forcefully quit the script. An option to override the check has been added.

## v0.4.0 (released on 2021-03-16)

### Changed

- [#168](https://github.com/vilhelmprytz/pterodactyl-installer/pull/168) panel: Use PHP version 8.0 over 7.4 for all supported installations (thanks [@Linux123123](https://github.com/Linux123123) for contributing!).

## v0.3.0 (released on 2021-02-24)

### Fixed

- [#151](https://github.com/vilhelmprytz/pterodactyl-installer/issues/151) panel: `APP_ENVIRONMENT_ONLY` was set to `true` when it should be `false`. This caused the panel to prohibit modifying the settings from the web interface, which is not intended behavior.
- [#165](https://github.com/vilhelmprytz/pterodactyl-installer/issues/165) panel: Fix so that the `pteroq` service uses the correct user on CentOS (thanks [@PipeItToDevNull](https://github.com/PipeItToDevNull) for reporting!).

### Changed

- [#129](https://github.com/vilhelmprytz/pterodactyl-installer/issues/129) wings: Clarify how to connect new Wings installation with the panel (using auto deploy).
- [#153](https://github.com/vilhelmprytz/pterodactyl-installer/pull/153) panel/wings: Changed so that the script will no longer tell you to open firewall ports if you have enabled automatic firewall configuration.
- [#153](https://github.com/vilhelmprytz/pterodactyl-installer/pull/153) panel: Remove deprecated third-party suggestions.

### Added

- [#148](https://github.com/vilhelmprytz/pterodactyl-installer/issues/148) wings: Added so that the Wings installation script will now verify FQDN using `lib/verify-fqdn` if the user chooses to configure Let's Encrypt automatically.

## v0.2.0 (released on 2021-01-18)

### Fixed

- [#113](https://github.com/vilhelmprytz/pterodactyl-installer/issues/113) panel: Fixed a bug that would cause the script to exit due to failing to create a "bus connection". Related to [#115](https://github.com/vilhelmprytz/pterodactyl-installer/issues/115) as well.
- [#135](https://github.com/vilhelmprytz/pterodactyl-installer/issues/135) panel/wings: Fixed so that the automatic ufw firewall configuration no longer requires confirming for the enable operation (user interaction after initial configuration is not intended behavior).

### Changed

- [#88](https://github.com/vilhelmprytz/pterodactyl-installer/issues/88) panel: Changed so that certbot now uses `certbot --nginx` over `certbot certonly` which makes it easier to perform certificate renewals later on (thanks [@Linux123123](https://github.com/Linux123123)).
- [#100](https://github.com/vilhelmprytz/pterodactyl-installer/pull/100) panel: Refactor several different functions in panel script, removal of redundant variables and functions and general cleanup/restructure (thanks [@Linux123123](https://github.com/Linux123123)).
- [#115](https://github.com/vilhelmprytz/pterodactyl-installer/issues/115) panel: Refactor timezone validation.
- [#137](https://github.com/vilhelmprytz/pterodactyl-installer/issues/137) panel: Removed ability to run `p:environment:mail` script since it's redundant.
- [#139](https://github.com/vilhelmprytz/pterodactyl-installer/pull/139) wings: Refactor - replaced all `"$var"` with `[ "$var" == true ]` (thanks [@Linux123123](https://github.com/Linux123123)).

### Added

- [098d01a](https://github.com/vilhelmprytz/pterodactyl-installer/commit/098d01a9729dffaf40e80077da2d7d51b42a197b) panel: Add a prompt in `verify-fqdn` that requires user consent before performing HTTPS request against [https://checkip.pterodactyl-installer.se](https://checkip.pterodactyl-installer.se).
- [#78](https://github.com/vilhelmprytz/pterodactyl-installer/issues/78) panel: Add option to auto-generate MySQL passwords and remember them throughout the installation.

## v0.1.1 (released on 2021-01-01)

### Fixed

- [#133](https://github.com/vilhelmprytz/pterodactyl-installer/issues/133) panel: Fixed the `verify-fqdn.sh` so that it now installs the packages quietly. Panel script will now only execute the FQDN verification if `ASSUME_SSL` or `CONFIGURE_LETSENCRYPT` is true.

## v0.1.0 (released on 2021-01-01)

- Initial release, introduces versioning to the project
