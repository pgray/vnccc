#!/bin/bash
set -e

BUILD_LOCAL=false
RELEASE=false
REPO_PATH="."
DD=${DD:-it}
IMAGE="ghcr.io/pgray/vnccc:main"

# Parse args
for arg in "$@"; do
    case $arg in
        --build)
            BUILD_LOCAL=true
            ;;
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

if [ "$BUILD_LOCAL" = true ]; then
    echo "Building vnccc container locally (release=$RELEASE)..."
    docker build --build-arg RELEASE=$RELEASE -t vnccc .
    IMAGE="vnccc"
else
    echo "Pulling latest vnccc image from GHCR..."
    docker pull "$IMAGE"
fi

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
    "$IMAGE"
