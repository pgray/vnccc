# vnccc: vnc claude code

Run Claude Code in a VNC Linux environment with web and Android clients.

## Quick Start

```bash
# Setup Claude Code authentication
claude setup-token
export CLAUDE_CODE_OAUTH_TOKEN=sk-...

# Run
./run.sh

# Access on port 8080 (via Tailscale)
```

## Prerequisites

- Rust (via [rustup](https://rustup.rs/))
- Linux environment (Arch Linux recommended)
- Claude Code installed and authenticated
- VNC client: noVNC (web) or bVNC (Android)

## Building

```bash
git clone <repo-url>
cd vnccc
cargo build --release
```

## Features

- Mobile-friendly with swype keyboard support
- Square display aspect ratio for Android
- Per-repository configuration
- Tailscale or Wireguard networking
- Session persistence with tmux

## Architecture

- **Display**: TigerVNC + X11
- **Terminal**: Alacritty
- **Network**: Tailscale or Wireguard
- **Web client**: noVNC
- **Automation**: Rust + Bash

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.
