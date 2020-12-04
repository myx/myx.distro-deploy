#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Reinstall(){
	if [ "--connect-ssh" = "$1" ] ; then
		shift
		set -e
		# set -x
		local sourceProject="$1" ; shift
		local targetCommand="$@"
		echo "Using Project: $sourceProject" >&2
		echo "Using Command: $targetCommand" >&2
		$targetCommand -t '
			test -x "`which screen`" && screen -s sh -q -O -U -D -R 
			test ! -x "`which screen`" && sh 
		'
		return 0
	fi
	
	if [ "--check-count" = "$1" ] ; then
		shift
		local sshTarget="$1"
		
		if [ -z "$2" ] ; then
			shift
			Reinstall --connect-ssh $sshTarget
			return 0
		fi
		
		echo "ERROR: Reinstall: More that one match: $@" >&2 ; return 1
	fi

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo "ERROR: Reinstall: 'filterProject' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	Require ListSshTargets
	. "`myx.common which lib/linesToArguments`"

	# set -x
	
	local targets="$( ListSshTargets --select-projects "$filterProject" "$@" | LinesToArguments )"

	# set +x

	if [ -z "$targets" ] ; then
		echo "ERROR: Reinstall: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2 ; return 1
	fi
	
	set -e
	eval Reinstall --check-count "$targets"
}

case "$0" in
	*/sh-scripts/Reinstall.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: Reinstall.fn.sh <project> [<ssh arguments>...]" >&2
			echo "syntax: Reinstall.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    Reinstall.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
			fi
			exit 1
		fi
		
		Reinstall "$@"
	;;
esac