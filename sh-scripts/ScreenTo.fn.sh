#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

ScreenTo(){

	set -e

	local MDSC_CMD='ScreenTo'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: 'filterProject' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	Require ListSshTargets

	local extraArguments="$( for argument in "$@" ; do printf '%q ' "$argument" ; done )"
	local defaultCommand="-t '[ -x \"\`which screen\`\" ] && env SHELL=\"\`which bash || which sh\`\" \`which screen\` -q -O -U -D -R || \`which bash || which sh\`'"

	local targets="$( ListSshTargets --select-projects "$filterProject" ${extraArguments:-$defaultCommand} | cut -d" " -f 2- )"

	if [ -z "$targets" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2
		return 1
	fi
	
	if [ "$targets" != "$( echo "$targets" | head -n 1 )" ] ; then
		echo "$MDSC_CMD: 🙋 STOP: More that one match: $@" >&2
		printf "Targets: \n%s\n" "$( echo "$targets" | sed -e 's|^|   |g' )" >&2
		return 2
	fi

	set -e
	echo "$MDSC_CMD: Using Command: $targets" >&2
	eval "$targets"
}

case "$0" in
	*/sh-scripts/ScreenTo.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ScreenTo.fn.sh <project> [<ssh arguments>...]" >&2
			echo "syntax: ScreenTo.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ScreenTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
				echo "    ScreenTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz -l mysql" >&2
			fi
			exit 1
		fi
		
		ScreenTo "$@"
	;;
esac