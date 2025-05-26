#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListSshTargets

type Prefix >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/lib/prefix"

ExecuteInteractive(){
	
	set -e

	case "$1" in
		--project)
			shift
			set -e
			local internSourceProject="$1" ; shift
			local internTargetCommand="$@"
			Prefix "$( echo $internTargetCommand | cut -d ' ' -f 2 )" $internTargetCommand
			return 0
		;;
		--all-targets)
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "ERROR: ListSshTargets: no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default ExecuteInteractive "$@"
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
	
	local sshTargets="$( \
		ListSshTargets --select-from-env \
			--line-prefix 'ExecuteInteractive --project' \
			--line-suffix ' ;' \
			-t "$@" \
	)"
	
	echo "Will execute: " >&2
	local textLine
	echo "$sshTargets" | while read textLine ; do
		echo "  $textLine" >&2
	done

	printf "\n%s\n" \
		"⏳ ...sleeping for 5 seconds..." \
		>&2
	sleep 5

	eval $sshTargets
}

case "$0" in
	*/sh-scripts/ExecuteInteractive.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ExecuteInteractive.fn.sh <search> --execute-stdin [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <search> --execute-script <script-name> [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <search> --execute-command <command> [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <search> --display-targets [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --select-{all|sequence|changed|none} " >&2
				echo "    --{select|filter|remove}-{projects|[merged-]provides|[merged-]keywords} <glob>" >&2
				echo "    --{select|filter|remove}-repository-projects <repositoryName>" >&2
				echo "  Examples:" >&2
				echo "    ExecuteInteractive.fn.sh --select-projects l6 -l root uname -a" >&2
				echo "    ExecuteInteractive.fn.sh --select-merged-keywords l6 -l root uname -a" >&2
				echo "    ExecuteInteractive.fn.sh --select-provides deploy-ssh-target: -l root uname -a" >&2
				echo "    ExecuteInteractive.fn.sh --select-all -l root uname -a" >&2
			fi
			exit 1
		fi
		
		ExecuteInteractive "$@"
	;;
esac