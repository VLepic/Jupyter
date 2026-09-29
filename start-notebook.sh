#!/bin/bash
set -euo pipefail

if [ "$(id -u)" = 0 ]; then
    echo "Run this image as its default jupyter user, not root. Configure NB_UID/NB_GID at build time." >&2
    exit 1
fi

if [ "${1:-}" = jupyter ] && [ "${2:-}" = lab ]; then
    for directory in "$HOME" /mnt/user/appdata/jupyter; do
        if [ ! -w "$directory" ]; then
            echo "Cannot write to $directory as $(id -u):$(id -g). Match NB_UID/NB_GID to the host directory owner and rebuild, or fix that directory's permissions on the host." >&2
            exit 1
        fi
    done
    umask 0002
    exec "$@" "--IdentityProvider.token=${JUPYTER_TOKEN:-}"
fi

exec "$@"
