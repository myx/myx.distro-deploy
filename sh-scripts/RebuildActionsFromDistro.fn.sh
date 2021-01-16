#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

type RebuildActions >/dev/null 2>&1 || \
	. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/RebuildActions.fn.sh"


RebuildActionsFromDistro(){
	if [ "$MDSC_INMODE" = "distro" ] ; then
		RebuildActions "$@"
	else
		( \
			. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include" ; \
			DistroShellContext --distro-path-auto
			RebuildActions "$@"
		)
	fi
}

case "$0" in
	*/sh-scripts/RebuildActionsFromDistro.fn.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		RebuildActionsFromDistro "$@"
	;;
esac