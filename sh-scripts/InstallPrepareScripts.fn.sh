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

InstallPrepareScripts(){
	set -e
	
	local projectName="$1" ; shift
	if [ -z "$projectName" ] ; then
		echo "ERROR: InstallPrepareScripts: 'projectName' argument is required!" >&2 ; return 1
	fi

	case "$1" in
		--print-files)
			( \
				ListProjectProvides "$projectName" --merge-sequence --filter-and-cut deploy-install-before ;
				ListProjectProvides "$projectName" --merge-sequence --filter-and-cut deploy-install-after | tail -r ;
			) \
			| while read -r projectName scriptPath ; do
				local fileName="$MDSC_SOURCE/$projectName/$scriptPath"
				if [ ! -f "$fileName" ] ; then
					echo "ERROR: InstallPrepareScripts: file is missing: $fileName" >&2; 
					return 1
				fi
				echo "$fileName"
			done
			return 0 
		;;
		--print-script)
			InstallPrepareScripts "$projectName" --print-files \
			| while read -r fileName ; do
				echo "#!/bin/sh"
				echo "#  start, $fileName"
				echo
				cat "$fileName"
				echo
				echo "#  end, $fileName"
			done
			return 0 
		;;
		--to-file)
			shift
			local targetFile="$1"
			if [ -z "$targetFile" ] ; then
				echo "InstallPrepareScripts: 'targetFile' argument is required!" >&2 ; return 1
			fi
			
			InstallPrepareScripts "$projectName" --print-script > "$targetFile"
			return 0 
		;;
		*)
			echo "ERROR: InstallPrepareScripts: invalid option: $1" >&2
			return 1
		;;
	esac
}

case "$0" in
	*/sh-scripts/InstallPrepareScripts.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: InstallPrepareScripts.fn.sh <project> --print-files/--print-script" >&2
			echo "syntax: InstallPrepareScripts.fn.sh <project> --to-file <targetDirectory>" >&2
			echo "syntax: InstallPrepareScripts.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareScripts.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz --print-script" >&2
				echo "    InstallPrepareScripts.fn.sh prv/hosts/setup.host-l6b2h1.myx.co.nz --print-files" >&2
				echo "    InstallPrepareScripts.fn.sh prv/hosts/setup.host-l6b2h1.myx.co.nz --print-script" >&2
			fi
			exit 1
		fi
		
		InstallPrepareScripts "$@"
	;;
esac