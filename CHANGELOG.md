# Changelog

All notable changes to maestro are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

Each release's section is also the body of its GitHub release.

## [Unreleased]

### Added

- `maestro version` prints the build version.
- `-h` on every command and action (`maestro server -h`, `maestro server start -h`) prints its own help.
- Install script: `curl -fsSL https://raw.githubusercontent.com/toki-voki/maestro/main/distribution/install.sh | sh`. Verifies SHA-256, prints the PATH line for your shell (fish/zsh/bash), `MAESTRO_MODIFY_PATH=1` appends it for you.
- Prebuilt binaries for Linux, macOS and Windows (amd64, arm64), plus deb/rpm/apk packages and a Homebrew tap.
- Server and client log to `$XDG_STATE_HOME/maestro/{server,client}.log` (rotated at 10 MB, 3 backups); the server also logs to stderr. Set the level with `--log-level` or `MAESTRO_LOG_LEVEL` (debug, info, warn, error) and the file with `--log-file` or `MAESTRO_SERVER_LOG_FILE` / `MAESTRO_CLIENT_LOG_FILE`.

[Unreleased]: https://github.com/toki-voki/maestro/commits/main
