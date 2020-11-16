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

FindDistroProvides(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "FindDistroProvides: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	shift

	local sshTarget="`ListProjectProvides "$projectName" --filter "deploy-ssh-target"`"
	if [ -z "$sshTarget" ] ; then
		echo "FindDistroProvides: $projectName does not have ssh target set!" >&2 ; return 1
	fi
	
	local sshHost="`echo "$sshTarget" | sed 's,:.*$,,'`"
	local sshPort="`echo "$sshTarget" | sed 's,^.*:,,'`"
	ssh $sshHost -p $sshPort "$@"
}

case "$0" in
	*/sh-scripts/find-distro-provides.sh)
		# find-distro-provides.sh --filter "distro-keywords:hz" --exec -l root -C "uname -a" 

		. "$( dirname $0 )/../sh-lib/DistroShellContext.include"
		DistroShellContext --distro-path-auto
		
		FindDistroProvides "$@"
	;;
esac