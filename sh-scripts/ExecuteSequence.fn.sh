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

ExecuteSequence(){
	
	set -e

	local projectsSelected=""
	case "$1" in
		--project)
			shift
			set -e
			local internSourceProject="$1" ; shift
			local internTargetCommand="$@"
			Prefix "$internSourceProject: $( echo $internTargetCommand | cut -d ' ' -f 2 )" $internTargetCommand
			return 0
		;;
		--all-targets)
		;;
		--select-from-env)
			shift
			local projectsSelected="$MMDENVSELECTION"
			if [ -z "$projectsSelected" ] ; then
				echo "ERROR: ListSshTargets: no projects selected!" >&2
				return 1
			fi
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default ExecuteSequence "$@"
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	while true ; do
		case "$1" in
			--no-cache)
				shift
				local useNoCache="--no-cache"
			;;
			--no-index)
				shift
				local useNoIndex="--no-index"
			;;
			*)
				break
			;;
		esac
	done

	local executeType=""
	local executeCommand=""
	local executeScriptName=""
	
	case "$1" in
		--display-targets)
			shift
			local executeType="--display-targets"
		;;
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
		--execute-command)
			shift
			local executeType="--execute-command"
			if [ -z "$1" ] ; then
				echo "ERROR: '--execute-command' - command argument required!" >&2 ; return 1
			fi
			local executeCommand="$1" ; shift
		;;
	esac

	local targetCommand="$@"

	local sshTargets="$( \
		ListSshTargets --select-from-env \
			--line-prefix 'ExecuteSequence --project' \
			--line-suffix ' ; ' \
			-T -o PreferredAuthentications=publickey -o ConnectTimeout=15 \
			$targetCommand $executeCommand \
	)"
	
	echo "Will execute: " >&2
	local textLine
	echo "$sshTargets" | while read textLine ; do
		echo "  $textLine" >&2
	done

	case "$executeType" in
		--display-targets)
			return 0
		;;
		--execute-stdin)
			echo 
			echo "...Enter script and press CTRL+D to execute or press CTRL+C to cancel..." >&2
			echo 
			local executeCommand="`cat`"

			local sshTargets="$( echo "$sshTargets" | while read textLine ; do 
				echo 'echo "$executeCommand" | '$textLine 
			done )"

			printf "\n%s\n" \
				"...got command, executing..." \
				>&2
		;;
		--execute-script)
			local executeCommand="`cat "$executeScriptName"`"
			local sshTargets="$( echo "$sshTargets" | while read textLine ; do 
				echo 'echo "$executeCommand" | '$textLine 
			done )"
			
			printf "\n%s\n%s\n" \
				"...got command, executing..." \
				"...sleeping for 5 seconds..." \
				>&2
			sleep 5
			echo
		;;
		*)
			printf "\n%s\n" \
				"...sleeping for 5 seconds..." \
				>&2
			sleep 5
		;;
	esac

	eval $sshTargets
}

case "$0" in
	*/sh-scripts/ExecuteSequence.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ExecuteSequence.fn.sh <search> --execute-stdin [<ssh arguments>...]" >&2
			echo "syntax: ExecuteSequence.fn.sh <search> --execute-script <script-name>  [<ssh arguments>...]" >&2
			echo "syntax: ExecuteSequence.fn.sh <search> --execute-command <command>  [<ssh arguments>...]" >&2
			echo "syntax: ExecuteSequence.fn.sh <search> --display-targets [<ssh arguments>...]" >&2
			echo "syntax: ExecuteSequence.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --select-{all|sequence|changed|none} " >&2
				echo "    --{select|filter|remove}-{projects|[merged-]provides|[merged-]keywords} <glob>" >&2
				echo "  Examples:" >&2
				echo "    ExecuteSequence.fn.sh --select-projects l6 --execute-stdin -l root" >&2
				echo "    ExecuteSequence.fn.sh --select-merged-keywords l6 --execute-stdin -l root bash" >&2
				echo "    ExecuteSequence.fn.sh --select-all uname -a" >&2
				echo "    ExecuteSequence.fn.sh --select-projects ndns- --execute-script source/ndm/cloud.all/setup.common-ndns/host/install/common-ndns-setup.txt -l root bash" >&2
			fi
			exit 1
		fi
		
		ExecuteSequence "$@"
	;;
esac