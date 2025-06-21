#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

Require ListSshTargets

type Prefix >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/lib/prefix"

ExecuteInteractive(){
	
	set -e

	local MDSC_CMD='ExecuteInteractive'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
	

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
				echo "⛔ ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default ExecuteInteractive "$@"
			return 0
		;;
	esac
	
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
			echo "syntax: ExecuteInteractive.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh <project-selector> --display-targets [<ssh arguments>...]" >&2
			echo "syntax: ExecuteInteractive.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-source/sh-lib/help/HelpSelectProjects.include"
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
