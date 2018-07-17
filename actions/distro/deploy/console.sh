#!/bin/sh

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

cd "$MMDAPP"
export MMDAPP
bash --rcfile "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/console-deploy-bashrc.rc"