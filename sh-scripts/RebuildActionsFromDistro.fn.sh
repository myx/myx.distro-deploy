#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

type RebuildActions >/dev/null 2>&1 || \
	. "$MDLT_ORIGIN/myx/myx.distro-source/sh-scripts/RebuildActions.fn.sh"


RebuildActionsFromDistro(){
	if [ "$MDSC_INMODE" = "deploy" ] ; then
		RebuildActions "$@"
	else
		( \
			. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.include" ; \
			DistroSystemContext --distro-path-auto
			RebuildActions "$@"
		)
	fi
}

case "$0" in
	*/sh-scripts/RebuildActionsFromDistro.fn.sh) 

		. "$( dirname $0 )/../../myx.distro-system/sh-lib/SystemContext.include"
		DistroSystemContext --distro-path-auto
		
		RebuildActionsFromDistro "$@"
	;;
esac
