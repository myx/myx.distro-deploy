#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListSshTargets

ExecuteInteractive(){
	
	if [ "$1" == "--project" ] ; then
		shift
		set -e
		local sourceProject="$1" ; shift
		local targetCommand="$@"
		
		. "$( myx.common which lib/prefix )"
		Prefix "$sourceProject" $targetCommand
		
		return 0
	fi

	local filterProjects="$1"
	if [ -z "$filterProjects" ] ; then
		echo "ERROR: ScreenTo: 'filterProjects' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	local sshTargets="$( ListSshTargets --filter-projects "$filterProjects" --line-prefix 'ExecuteInteractive --project' --line-suffix ' ;' -t "$@" )"
	
	echo "Will execute: " >&2
	local textLine
	echo "$sshTargets" | while read textLine ; do
		echo "  $textLine" >&2
		echo >&2
	done
	
	echo
	echo "...sleeping for 5 seconds..." >&2
	sleep 5
	
	eval $sshTargets
}

case "$0" in
	*/sh-scripts/ExecuteInteractive.fn.sh)
		# ExecuteInteractive.fn.sh  
		# ExecuteInteractive.fn.sh --no-project
		# ExecuteInteractive.fn.sh --no-target
		# ExecuteInteractive.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ExecuteInteractive.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ExecuteInteractive.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ExecuteInteractive.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ExecuteInteractive.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ExecuteInteractive.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait
		
		ExecuteInteractive "$@"
	;;
esac