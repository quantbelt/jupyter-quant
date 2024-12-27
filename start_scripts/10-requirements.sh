#!/usr/bin/bash

###############################################################################
#
# if you need ssh keys make sure that SSH_PASSPHRASE or SSH_PASSPHRASE_FILE is
# set so 00-ssh-agent.sh can load ssh keys
#
# put your packages in /home/gordon/Notebooks/requirements.txt
#
###############################################################################

if [ -f "$JUPYTER_SERVER_ROOT"/requirements.txt ]; then
	pip install -U -r "$JUPYTER_SERVER_ROOT"/requirements.txt
fi
