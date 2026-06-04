# fora-cli

Public binary mirror for the Fora CLI. Built from the private source repo at
[KaneLabs/fora-markets](https://github.com/KaneLabs/fora-markets).

## Install

```
curl -fsSL https://install.fora.co/install.sh | sh
```

The installer detects your platform, downloads the matching tarball from this
repo's Releases, verifies sha256, and drops the binary in `/usr/local/bin` (or
`~/.local/bin` if `/usr/local/bin` isn't writable).

## Supported platforms

| OS    | Arch    | Target                          |
|-------|---------|---------------------------------|
| Linux | x86_64  | `x86_64-unknown-linux-musl`     |
| Linux | aarch64 | `aarch64-unknown-linux-musl`    |

Linux binaries are statically linked against musl — they run on any distro
without dynamic library version concerns.

## macOS

No prebuilt macOS binary. Build from source (requires Rust toolchain + SSH
access to the source repo):

```
cargo install --git git@github.com:KaneLabs/fora-markets.git fora-cli
```

## Verifying a download manually

Each tarball ships with a companion `.sha256` file. Download both and run:

```
TARGET="$(uname -m | sed s/arm64/aarch64/)-unknown-linux-musl"
curl -LO https://github.com/KaneLabs/fora-cli/releases/latest/download/fora-cli-${TARGET}.tar.gz
curl -LO https://github.com/KaneLabs/fora-cli/releases/latest/download/fora-cli-${TARGET}.tar.gz.sha256
shasum -a 256 -c fora-cli-${TARGET}.tar.gz.sha256
tar -xzf fora-cli-${TARGET}.tar.gz
```

## Releases

Releases are produced automatically by the source-repo CI on every push to
`main` that touches fora-cli or its deps. The `fora-cli-latest` tag is rolling;
versioned tags (`fora-cli-v0.1.0`, etc.) are immutable.

## Issues / source

Bug reports and PRs go to the source repo: https://github.com/KaneLabs/fora-markets
