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

type Prefix >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/lib/prefix"
#	. "$( myx.common which lib/prefix )"

ExecuteSequence(){
	
	if [ "$1" == "--project" ] ; then
		shift
		set -e
		local sourceProject="$1" ; shift
		local targetCommand="$@"
		
		Prefix "$sourceProject: $( echo $targetCommand | cut -d ' ' -f 2 )" $targetCommand
		
		return 0
	fi

	local filterProjects="$1"
	if [ -z "$filterProjects" ] ; then
		echo "ERROR: ScreenTo: 'filterProjects' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	case "$1" in
		--execute-stdin)
			shift
			local executeType="--execute-stdin"
		;;
		--execute-script)
			shift
			local executeType="--execute-script"
			if [ -z "$1" ] ; then
				echo "ERROR: '--execute-script' - file pathname argument required!" >&2 ; return 1
			fi
			local executeScriptName="$1" ; shift
			if [ ! -f "$executeScriptName" ] ; then
				echo "ERROR: '--execute-script $executeScriptName' - file is not available!" >&2 ; return 1
			fi
		;;
		*)
			local executeType="--execute-default"
			local executeCommand=""
		;;
	esac

	local targetCommand="$@"

	local sshTargets="$( ListSshTargets --filter-projects "$filterProjects" --line-prefix 'ExecuteSequence --project' --line-suffix ' ; ' -T -o PreferredAuthentications=publickey -o ConnectTimeout=15 $targetCommand )"
	
	echo "Will execute: " >&2
	local textLine
	echo "$sshTargets" | while read textLine ; do
		printf "  %q" $textLine >&2
		echo >&2
	done

	case "$executeType" in
		--execute-stdin)
			echo 
			echo "...Enter script and press CTRL+D to execute or press CTRL+C to cancel..." >&2
			echo 

			local executeCommand="`cat`"
			local sshTargets="$(echo "$sshTargets" | while read textLine ; do 
				echo 'echo "$executeCommand" | '$textLine 
			done)"

			echo 
			echo "...got command, executing..." >&2
			echo
		;;
		--execute-script)
			local executeCommand="`cat "$executeScriptName"`"
			local sshTargets="$(echo "$sshTargets" | while read textLine ; do 
				echo 'echo "$executeCommand" | '$textLine 
			done)"
			
			echo
			echo "...got command, executing..." >&2
			echo "...sleeping for 5 seconds..." >&2
			sleep 5
			echo
		;;
		*)
			echo
			echo "...sleeping for 5 seconds..." >&2
			sleep 5
		;;
	esac

	eval $sshTargets
}

case "$0" in
	*/sh-scripts/ExecuteSequence.fn.sh)
		# ExecuteSequence.fn.sh  
		# ExecuteSequence.fn.sh --no-project
		# ExecuteSequence.fn.sh --no-target
		# ExecuteSequence.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ExecuteSequence.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ExecuteSequence.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ExecuteSequence.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ExecuteSequence.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ExecuteSequence.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait
		#
		# ExecuteSequence.fn.sh ndls --execute-stdin -l root bash
		# ExecuteSequence.fn.sh ndss- -l root "date ; ndss upgrade ; ndss restart ; sleep 300"
		# ExecuteSequence.fn.sh ndns- --execute-script source/ndm/cloud.all/setup.common-ndns/host/install/common-ndns-setup.txt -l root bash
		
		ExecuteSequence "$@"
	;;
esac