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

Require ListSshTargets

type Prefix >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/lib/prefix"
#	. "$( myx.common which lib/prefix )"

ExecuteInteractive(){
	
	if [ "$1" == "--project" ] ; then
		shift
		set -e
		local internSourceProject="$1" ; shift
		local internTargetCommand="$@"
		
		Prefix "$internSourceProject: $( echo $internTargetCommand | cut -d ' ' -f 2 )" $internTargetCommand
		
		return 0
	fi

	set -e

	local filterProjects=""

	while true ; do
		case "$1" in
			--all)
				shift
				local filterProjects="$filterProjects --all"
				break
			;;
			--filter-projects)
				shift
				local filterProjects="$filterProjects --filter-projects $1" ; shift
			;;
			--filter-keywords)
				shift
				local filterProjects="$filterProjects --filter-keywords $1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$filterProjects" ] ; then
		echo "ERROR: ExecuteInteractive: 'filterProjects' argument (name or keyword or substring) is required!" >&2
		return 1
	fi

	local sshTargets="$( ListSshTargets $filterProjects --line-prefix 'ExecuteInteractive --project' --line-suffix ' ;' -t "$@" )"
	
	echo "Will execute: " >&2
	local textLine
	echo "$sshTargets" | while read textLine ; do
		printf "  %q" $textLine >&2
		echo >&2
	done
	
	echo
	echo "...sleeping for 5 seconds..." >&2
	sleep 5
	
	eval $sshTargets
}

case "$0" in
	*/sh-scripts/ExecuteInteractive.fn.sh)
		# ExecuteInteractive.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ExecuteInteractive.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ExecuteInteractive.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ExecuteInteractive.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ExecuteInteractive.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ExecuteInteractive.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ExecuteInteractive.fn.sh <search> --execute-stdin [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <search> --execute-script <script-name>  [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <search> --execute-command <command>  [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <search> --display-targets [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --all / --filter-projects <glob> / --filter-keywords <keyword>" >&2
				echo "  Examples:" >&2
				echo "    ExecuteInteractive.fn.sh --filter-projects l6 -l root uname -a" >&2
				echo "    ExecuteInteractive.fn.sh --filter-keywords l6 -l root uname -a" >&2
				echo "    ExecuteInteractive.fn.sh --filter-provides deploy-ssh-target -l root uname -a" >&2
				echo "    ExecuteInteractive.fn.sh --all -l root uname -a" >&2
			fi
			exit 1
		fi
		
		ExecuteInteractive "$@"
	;;
esac