# Changelog

This project follows the [semantic versioning](https://semver.org) convention. Changelog points should be divided into fixed, changed, or added.

## next-release

### Fixed

- [#135](https://github.com/vilhelmprytz/pterodactyl-installer/issues/135) Fixed so that the automatic ufw firewall configuration no longer requires confirming for the enable operation (user interaction after initial configuration is not intended behavior).

### Added

- Add a prompt in `verify-fqdn` that requires user consent before performing HTTPS request against [https://checkip.pterodactyl-installer.se](https://checkip.pterodactyl-installer.se).

## v0.1.1 (released on 2021-01-01)

### Fixed

- [#133](https://github.com/vilhelmprytz/pterodactyl-installer/issues/133) Fixed the `verify-fqdn.sh` so that it now installs the packages quietly. Panel script will now only execute the FQDN verification if `ASSUME_SSL` or `CONFIGURE_LETSENCRYPT` is true.

## v0.1.0 (released on 2021-01-01)

- Initial release, introduces versioning to the project
