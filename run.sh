#!/bin/bash
set -e

RELEASE=false
REPO_PATH="."
DD=${DD:-it}

# Parse args
for arg in "$@"; do
    case $arg in
        --release)
            RELEASE=true
            ;;
        *)
            REPO_PATH="$arg"
            ;;
    esac
done

# Resolve to absolute path
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

echo "Building vnccc container (release=$RELEASE)..."
docker build --build-arg RELEASE=$RELEASE -t vnccc .

echo "Starting vnccc with repo: $REPO_PATH"
echo "Open http://localhost:8080 in your browser"

# Remove any existing container with same name
docker rm -f vnccc 2>/dev/null || true

MOUNT_OPTS=()
MOUNT_OPTS+=(-v "$REPO_PATH:/repo:rw")
[ -f "$HOME/.gitconfig" ] && MOUNT_OPTS+=(-v "$HOME/.gitconfig:/tmp/host-gitconfig:ro")
[ -f "$HOME/.claude.json" ] && MOUNT_OPTS+=(-v "$HOME/.claude.json:/tmp/host-claude.json:ro")
[ -d "$HOME/.ssh" ] && MOUNT_OPTS+=(-v "$HOME/.ssh:/tmp/host-ssh:ro")
[ -d "$HOME/.claude" ] && MOUNT_OPTS+=(-v "$HOME/.claude:/tmp/host-claude:rw")
[ -d "$HOME/.config/claude" ] && MOUNT_OPTS+=(-v "$HOME/.config/claude:/tmp/host-claude-config:rw")
[ -d "$HOME/.config/gh" ] && MOUNT_OPTS+=(-v "$HOME/.config/gh:/tmp/host-gh-config:rw")

echo "Mount options: ${MOUNT_OPTS[@]}"

docker run "-${DD}" --rm \
    -p 8080:8080 \
    -p 6080:6080 \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -e HOST_USER="$(whoami)" \
    -e CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN}" \
    "${MOUNT_OPTS[@]}" \
    --name vnccc \
    vnccc
