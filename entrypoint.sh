#!/usr/bin/env bash
###############################################################################
# entrypoint.sh
#
# docker jupyter
#
# entrypoint script for jupyter docker image. it starts jupyter-lab by
# default.
#
###############################################################################

set -e

DAEMON=jupyter-lab

# APT Proxy Cache
if [ -n "${APT_PROXY}" ]; then
    echo "Acquire::http { Proxy "'$APT_PROXY'"; }"  \
      | sudo tee /etc/apt/apt.conf.d/01proxy
fi;

# dotfiles
if [ -d "$BYODF" ]; then
    echo "> setting dotfiles 📌 at $BYODF"
    stow --adopt -t "$HOME" -d "$(dirname "$BYODF")" "$(basename "$BYODF")"
    git -C "$BYODF" reset --hard
fi;

# jupyterlab-lsp
JUPYTER_OPT='--ContentsManager.allow_hidden=True'

# language server symlink
if [ ! -L "${JUPYTER_SERVER_ROOT}"/.lsp_symlink ]; then
    ln -s / .lsp_symlink
fi;

if [[ -n "$PIP_REQUIRE_VIRTUALENV" ]]; then
    echo "PIP_REQUIRE_VIRTUALENV set to: $PIP_REQUIRE_VIRTUALENV"
else
    PIP_REQUIRE_VIRTUALENV=false
    export PIP_REQUIRE_VIRTUALENV=false
fi

stop() {
    echo "> Received SIGINT or SIGTERM. Shutting down $DAEMON"
    # Get PID
    local pid
    pid=$(cat /tmp/$DAEMON.pid)
    # Set TERM
    kill -SIGTERM "${pid}"
    # Wait for exit
    wait "${pid}"
    # All done.
    echo "> Done... $?"
}

echo "> Running Jupyter-lab 🐍"
echo "> Running as $(id)"
echo "> Parameters: $*"
echo "> Jupyter options: $JUPYTER_OPT"

if [ "$(basename "$1" 2> /dev/null)" == "$DAEMON" ]; then

    echo "> Starting $* $JUPYTER_OPT"
    trap stop SIGINT SIGTERM
    "$@" "${JUPYTER_OPT}" &
    pid="$!"
    echo $pid > /tmp/$DAEMON.pid
    echo "> $DAEMON pid: $pid"
    wait "${pid}"
    exit $?

elif echo "$*" | grep ^-- ; then
    # accept parameters from command line or compose
    echo "> Starting $* $JUPYTER_OPT"
    trap stop SIGINT SIGTERM
    jupyter-lab --no-browser --ip=0.0.0.0 "${JUPYTER_OPT}" "$@" &
    pid="$!"
    echo "$pid" > /tmp/"$DAEMON".pid
    echo "> $DAEMON pid: $pid"
    wait "${pid}"
    exit $?
else
    # run command from docker run
    echo "> Starting $* "
    exec "$@" 
fi
