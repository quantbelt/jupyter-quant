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
JUPYTER_OPT=''

[ -n "$NOTEBOOK_DIR" ] && JUPYTER_OPT+=" --notebook-dir=${NOTEBOOK_DIR}"

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

echo "> Running Jupyter-lab"
echo "> Running as $(id)"
echo "> Parameters: $*"
if [ "$(basename "$1")" == "$DAEMON" ]; then

    echo "> Starting $* ... $JUPYTER_OPT"
    trap stop SIGINT SIGTERM
    "$@" "${JUPYTER_OPT}" &
    pid="$!"
    echo $pid > /tmp/$DAEMON.pid
    echo "> $DAEMON pid: $pid"
    wait "${pid}"
    exit $?

elif echo "$*" | grep ^-- ; then
    # accept parameters from command line or compose
    echo "> Starting $* ... $JUPYTER_OPT"
    trap stop SIGINT SIGTERM
    jupyter-lab --no-browser --ip 0.0.0.0 "$@" "${JUPYTER_OPT}" &
    pid="$!"
    echo "$pid" > /tmp/"$DAEMON".pid
    echo "> $DAEMON pid: $pid"
    wait "${pid}"
    exit $?
else
    # run command from docker run
    exec "$@"
fi
