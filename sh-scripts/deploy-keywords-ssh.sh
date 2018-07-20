#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if [ "`type -t ListProjectProvides`" != "function" ] ; then
. "$MMDAPP/source/myx/myx.distro-source/sh-scripts/ListProjectProvides.fn.sh"
fi

DeployKeywordsSsh(){
	local KWD="$1"
	if [ -z "$KWD" ] ; then
		echo "DeployKeywordsSsh: 'KWD' argument is required!" >&2 ; exit 1
	fi
	
	shift

	# TODO
	# FindDistroProjects --provides-value deploy-keywords "$KWD"
}

case "$0" in
	*/sh-scripts/deploy-keywords-ssh.sh)
		# deploy-keywords-ssh.sh "ndss knt r3" -l root -C "uname -a" 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		DeployKeywordsSsh "$@"
	;;
esac