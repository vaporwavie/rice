#!/usr/bin/bash
# Runs the Todoist CLI for the bar without relying on the caller's PATH, fnm's per-shell setup, or which Node fnm defaults to.
set -u
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
fnm="${FNM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/fnm}"

# td loads a native keyring module built for its own Node, so each entry runs under the node beside it.
installs=("$fnm/aliases/default")
mapfile -t -O 1 installs < <(printf '%s\n' "$fnm"/node-versions/*/installation | sort -rV)
for install in "${installs[@]}"; do
    entry="$install/lib/node_modules/@doist/todoist-cli/dist/index.js"
    if [[ -f $entry && -x $install/bin/node ]]; then
        PATH="$install/bin:${PATH:-/usr/bin:/bin}" exec "$install/bin/node" "$entry" "$@"
    fi
done
echo "Todoist CLI not found under $fnm; run npm install -g @doist/todoist-cli" >&2
exit 127
