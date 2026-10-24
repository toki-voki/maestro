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

[Unreleased]: https://github.com/toki-voki/maestro/commits/main
