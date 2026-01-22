#!/bin/bash
set -e

# Allow passwordless su to root
passwd -d root

# Create user with host UID/GID
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
HOST_USER="${HOST_USER:-vncuser}"

echo "Creating user $HOST_USER with UID=$HOST_UID GID=$HOST_GID"

# Create group if it doesn't exist
groupadd -g "$HOST_GID" "$HOST_USER" 2>/dev/null || true

# Create user if it doesn't exist
useradd -m -u "$HOST_UID" -g "$HOST_GID" -s /bin/bash "$HOST_USER" 2>/dev/null || true

USER_HOME="/home/$HOST_USER"

# Copy config files to user's home
if [ -f /tmp/host-gitconfig ]; then
    cp /tmp/host-gitconfig "$USER_HOME/.gitconfig"
    chown "$HOST_UID:$HOST_GID" "$USER_HOME/.gitconfig"
fi

if [ -f /tmp/host-claude.json ]; then
    cp /tmp/host-claude.json "$USER_HOME/.claude.json"
    chown "$HOST_UID:$HOST_GID" "$USER_HOME/.claude.json"
fi

if [ -d /tmp/host-ssh ]; then
    cp -r /tmp/host-ssh "$USER_HOME/.ssh"
    chown -R "$HOST_UID:$HOST_GID" "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh"/* 2>/dev/null || true
fi

echo "Checking claude config directories..."
echo "Host .claude contents:" && ls -la /tmp/host-claude 2>/dev/null || echo "(not mounted)"
echo "Host .config/claude contents:" && ls -la /tmp/host-claude-config 2>/dev/null || echo "(not mounted)"

# Use symlinks so claude can read/write directly to host configs
if [ -d /tmp/host-claude ]; then
    ln -sf /tmp/host-claude "$USER_HOME/.claude"
    chown -h "$HOST_UID:$HOST_GID" "$USER_HOME/.claude"
    echo "Symlinked $USER_HOME/.claude -> /tmp/host-claude"
fi

if [ -d /tmp/host-claude-config ]; then
    mkdir -p "$USER_HOME/.config"
    chown "$HOST_UID:$HOST_GID" "$USER_HOME/.config"
    ln -sf /tmp/host-claude-config "$USER_HOME/.config/claude"
    chown -h "$HOST_UID:$HOST_GID" "$USER_HOME/.config/claude"
    echo "Symlinked $USER_HOME/.config/claude -> /tmp/host-claude-config"
fi

if [ -d /tmp/host-gh-config ]; then
    mkdir -p "$USER_HOME/.config"
    chown "$HOST_UID:$HOST_GID" "$USER_HOME/.config"
    ln -sf /tmp/host-gh-config "$USER_HOME/.config/gh"
    chown -h "$HOST_UID:$HOST_GID" "$USER_HOME/.config/gh"
    echo "Symlinked $USER_HOME/.config/gh -> /tmp/host-gh-config"
fi

# Copy alacritty config
mkdir -p "$USER_HOME/.config/alacritty"
cp /app/alacritty.toml "$USER_HOME/.config/alacritty/alacritty.toml"
chown -R "$HOST_UID:$HOST_GID" "$USER_HOME/.config/alacritty"

# Setup .bashrc with Claude environment
CLAUDE_DIR="/tmp/host-claude"
[ ! -d "$CLAUDE_DIR" ] && CLAUDE_DIR="$USER_HOME/.claude"

cat >> "$USER_HOME/.bashrc" << BASHRC

# Claude Code configuration
export PATH="/usr/local/bin:/usr/bin:/bin:\$PATH"
BASHRC
chown "$HOST_UID:$HOST_GID" "$USER_HOME/.bashrc"

# Run vnccc as the user
echo "Contents:" && ls -la "$CLAUDE_DIR" 2>/dev/null || echo "(empty)"
echo "Credentials check:" && ls -la "$CLAUDE_DIR/.credentials.json" 2>/dev/null || echo "(no credentials file)"

# Use 'su' without '-' to preserve more environment, but still set critical vars
exec su "$HOST_USER" -c "export HOME=$USER_HOME && export PATH=/usr/local/bin:/usr/bin:/bin:\$PATH && /app/target/vnccc $*"
