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

type Prefix >/dev/null 2>&1 || \
	. "${MYXROOT:-/usr/local/share/myx.common}/bin/lib/prefix.Common"

type DistroImage >/dev/null 2>&1 || \
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"

ExecuteInteractive(){
	
	set -e

	local MDSC_CMD='ExecuteInteractive'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
	
	case "$1" in
		--project)
			shift
			set -e
			## <project> <target> <command...>: the target names the output, the command runs.
			local internSourceProject="$1" internTargetName="$2" ; shift 2
			Prefix "$internTargetName" "$@"
			return 0
		;;
		--all-targets)
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "$MDSC_CMD: ⛔ ERROR: no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default ExecuteInteractive "$@"
			return 0
		;;
	esac
	
	## Each argument quoted once more: the eval below strips one layer and DistroSshConnect's
	## own eval the other, so only the remote shell parses `;`, `|`, `$` or quotes in them.
	local argument targetArguments=()
	for argument in "$@" ; do targetArguments+=( "$( printf '%q' "$argument" )" ) ; done
	## Each line becomes `ExecuteInteractive --project <project> <target> DistroSshConnect <ssh options> ;`.
	local sshTargets="$( \
		Distro ListSshTargets --select-from-env \
			--line-prefix 'DistroSshConnect ' \
			--line-suffix ' ;' \
			-t ${targetArguments[@]+"${targetArguments[@]}"} \
		| awk '{ print "ExecuteInteractive --project", $1, $2, substr($0, index($0, $3)) }'
	)"
	# | cut -d" " -f 2,3,1,4- # cut can't reorder columns
	
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
			echo "📘 syntax: ExecuteInteractive.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]" >&2
			echo "📘 syntax: ExecuteInteractive.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]" >&2
			echo "📘 syntax: ExecuteInteractive.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]" >&2
			echo "📘 syntax: ExecuteInteractive.fn.sh <project-selector> --display-targets [<ssh arguments>...]" >&2
			echo "📘 syntax: ExecuteInteractive.fn.sh [--help]" >&2
			. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/help/Help.ExecuteInteractive.include"
			exit 1
		fi
		
		ExecuteInteractive "$@"
	;;
esac
