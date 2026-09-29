#!/bin/bash
set -euo pipefail

if [ "$(id -u)" = 0 ]; then
    if [ "${1:-}" = jupyter ] && [ "${2:-}" = lab ] && [ "${FIX_PERMISSIONS:-1}" = 1 ]; then
        notebook_uid=$(id -u jupyter)
        notebook_gid=$(id -g jupyter)
        for directory in /home/jupyter /mnt/user/appdata/jupyter; do
            if [ -L "$directory" ]; then
                echo "Refusing to repair a symlink as the data directory: $directory" >&2
                exit 1
            fi
            echo "Checking permissions in $directory for $notebook_uid:$notebook_gid"
            # Do not follow symlinks or descend into nested filesystems.
            find -P "$directory" -xdev \( -type d -o -type f \) \
                \( ! -uid "$notebook_uid" -o ! -gid "$notebook_gid" \) \
                -exec chown --no-dereference "$notebook_uid:$notebook_gid" {} +
            find -P "$directory" -xdev -type d ! -perm -u=rwx -exec chmod u+rwx {} +
            find -P "$directory" -xdev -type f ! -perm -u=rw -exec chmod u+rw {} +
        done
    fi
    exec setpriv --reuid=jupyter --regid="$(id -g jupyter)" --init-groups \
        /bin/bash /usr/local/bin/start-notebook.sh "$@"
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
