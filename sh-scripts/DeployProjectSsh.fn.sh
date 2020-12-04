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
	local projectName="$1" ; shift
	if [ -z "$projectName" ] ; then
		echo "DeployProjectSsh: 'projectName' argument is required!" >&2 ; return 1
	fi
	
	local doFiles
	local doScripts
	case "$1" in
		--do-exec|--do-scripts)
			local doScripts="true"
		;;
		--do-sync|--do-files)
			local doFiles="true"
		;;
		--do-full|--do-both)
			local doScripts="true"
			local doFiles="true"
		;;
		'')
			echo "ERROR: DeployProjectSsh: --do-exec/--do-sync/--do-both must be specified" >&2
			return 1
		;;
		*)
			echo "ERROR: DeployProjectSsh: invalid option: $1" >&2
			return 1
		;;
	esac

	local sshTarget="`ListProjectProvides "$projectName" --print-provides-only --filter-and-cut deploy-ssh-target`"
	if [ -z "$sshTarget" ] ; then
		echo "ERROR: DeployProjectSsh: $projectName does not have ssh target set!" >&2
		return 1
	fi
	
	local sshHost="`echo "$sshTarget" | sed 's,:.*$,,'`"
	local sshPort="`echo "$sshTarget" | sed 's,^.*:,,'`"
	
	if [ -d "$MMDAPP/output" ] ; then
		local cacheFolder="$MMDAPP/output/deploy/$projectName"
	else
		local cacheFolder="`mktemp -d -t MDSC_DPS`"
		trap "rm -rf $cacheFolder" EXIT
	fi
	
	mkdir -p "$cacheFolder"
	
	
	if [ ! -z "$doFiles" ] ; then
		Require InstallPrepareFiles
		InstallPrepareFiles "$projectName" --to-directory "$cacheFolder/sync"
	fi
	if [ ! -z "$doScripts" ] ; then
		Require InstallPrepareScripts
		InstallPrepareScripts "$projectName" --to-file "$cacheFolder/exec"
	fi
	
	# ssh $sshHost -p $sshPort "$@"
}

case "$0" in
	*/sh-scripts/DeployProjectSsh.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DeployProjectSsh.fn.sh <project> --do-exec/--do-sync/--do-both" >&2
			echo "syntax: DeployProjectSsh.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    DeployProjectSsh.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
			fi
			exit 1
		fi
		
		DeployProjectSsh "$@"
	;;
esac