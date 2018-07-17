#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

type ListAllRepositories >/dev/null 2>&1 || \
. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListAllRepositories.fn.sh"

DISTRO_PATH="$MMDAPP/distro"

MakeDistroOutputs(){
	echo "Will build all builders..."
}

case "$0" in
	*/sh-scripts/make-distro-outputs.sh) 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-default
		
		MakeDistroOutputs "$@"
	;;
esac