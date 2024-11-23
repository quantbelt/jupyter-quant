#!/usr/bin/bash

###############################################################################
#
# requires SSH_PASSPHRASE or SSH_PASSPHRASE_FILE to be set
#
###############################################################################

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		printf >&2 'error: both %s and %s are set (but are exclusive)\n' "$var" "$fileVar"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(<"${!fileVar}")"
	fi
	export "$var"="$val"
	#unset "$fileVar"
}

# usage: unset_env VAR
#	ie: unset_env 'XYZ_DB_PASSWORD'
unset_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	if [ "${!fileVar:-}" ]; then
		unset "$var"
	fi
}

file_env 'SSH_PASSPHRASE'
if [ -n "$SSH_PASSPHRASE" ]; then

	if ! pgrep ssh-agent >/dev/null; then
		# start agent if it's not already running
		# https://wiki.archlinux.org/title/SSH_keys#SSH_agents
		echo ".> Starting ssh-agent."
		ssh-agent >"${HOME}/.ssh-agent.env"
		source "${HOME}/.ssh-agent.env"
	else
		echo ".> ssh-agent already running"
		if [ -z "${SSH_AUTH_SOCK}" ]; then
			echo ".> Loading agent environment"
			source "${HOME}/.ssh-agent.env"
		fi
	fi
	echo ".> ssh-agent sock: ${SSH_AUTH_SOCK:-no agent}"

	if ls "${HOME}"/.ssh/id_* >/dev/null; then
		echo ".> Adding keys to ssh-agent."
		export SSH_ASKPASS_REQUIRE=never
		SSHPASS="${SSH_PASSPHRASE}" sshpass -e -P "passphrase" ssh-add
		unset_env 'SSH_PASSPHRASE'
		echo ".> ssh-agent identities: $(ssh-add -l)"
	else
		echo ".> SSH keys not found, ssh-agent not started"
	fi
fi
