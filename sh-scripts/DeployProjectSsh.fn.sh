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

Require ListProjectProvides

DeployProjectSsh(){
	local projectName="$1"
	if [ -z "$projectName" ] ; then
		echo "DeployProjectSsh: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	shift

	local sshTarget="`ListProjectProvides "$projectName" --filter "deploy-ssh-target"`"
	if [ -z "$sshTarget" ] ; then
		echo "DeployProjectSsh: $projectName does not have ssh target set!" >&2 ; return 1
	fi
	
	local sshHost="`echo "$sshTarget" | sed 's,:.*$,,'`"
	local sshPort="`echo "$sshTarget" | sed 's,^.*:,,'`"
	ssh $sshHost -p $sshPort "$@"
}

case "$0" in
	*/sh-scripts/DeployProjectSsh.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DeployProjectSsh.fn.sh <project> [<ssh arguments>...]" >&2
			echo "syntax: DeployProjectSsh.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    DeployProjectSsh.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
				echo "    DeployProjectSsh.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz -l root -C 'uname -a'" >&2
			fi
			exit 1
		fi
		
		DeployProjectSsh "$@"
	;;
esac