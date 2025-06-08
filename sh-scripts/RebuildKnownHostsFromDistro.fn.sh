#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

type RebuildKnownHosts >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/RebuildKnownHosts.fn.sh"


RebuildKnownHostsFromDistro(){
	if [ "$MDSC_INMODE" = "deploy" ] ; then
		RebuildKnownHosts "$@"
	else
		( \
			. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include" ; \
			DistroShellContext --distro-path-auto
			RebuildKnownHosts "$@"
		)
	fi
}

case "$0" in
	*/sh-scripts/RebuildKnownHostsFromDistro.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		RebuildKnownHostsFromDistro "$@"
	;;
esac
