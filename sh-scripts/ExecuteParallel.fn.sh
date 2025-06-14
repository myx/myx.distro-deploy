#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDSC_ORIGIN" ] || ! type DistroShellContext >/dev/null 2>&1 ; then
	. "${MDSC_ORIGIN:=${MDLT_ORIGIN:=$MMDAPP/.local}}/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListSshTargets

type Prefix >/dev/null 2>&1 || \
	. "/usr/local/share/myx.common/bin/lib/prefix"

ExecuteParallel(){

	set -e

	local MDSC_CMD='ExecuteParallel'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	case "$1" in
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
			ListDistroProjects --select-execute-default ExecuteParallel "$@"
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	local useSshHost="${useSshHost:-}"
	local useSshPort="${useSshPort:-}"
	local useSshUser="${useSshUser:-}"
	local useSshHome="${useSshHome:-}"

	local executeSleep="${executeSleep:-true}"
	local explainTasks="${explainTasks:-true}"

	local executePostProcess=""

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
			--no-sleep)
				shift
				executeSleep="false"
			;;
			--non-interactive)
				shift
				executeSleep="false"
				explainTasks="false"
			;;
			--ssh-name|--ssh-host|--ssh-port|--ssh-user|--ssh-home|--ssh-args)
				DistroImageParseSshOptions "$1" "$2"
				shift ; shift
			;;
			--ssh-*)
				echo "$MDSC_CMD: ⛔ ERROR: invalid --ssh-XXXX option: $1" >&2
				set +e ; return 1
			;;
			--execute-post-process)
				shift
				if [ -z "$1" ] ; then
					echo "$MDSC_CMD: ⛔ ERROR: '--execute-post-process' - command argument required!" >&2
					set +e ; return 1
				fi
				local executePostProcess="$1" ; shift
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
				echo "$MDSC_CMD: ⛔ ERROR: '--execute-script' - file pathname argument required!" >&2
				set +e ; return 1
			fi
			local executeScriptName="$MMDAPP/source/${1#"$MMDAPP/source/"}" ; shift
			if [ ! -f "$executeScriptName" ] ; then
				echo "$MDSC_CMD: ⛔ ERROR: '--execute-script $executeScriptName' - file is not available!" >&2
				set +e ; return 1
			fi
		;;
		--execute-command)
			shift
			local executeType="--execute-command"
			if [ -z "$1" ] ; then
				echo "$MDSC_CMD: ⛔ ERROR: '--execute-command' - command argument required!" >&2
				set +e ; return 1
			fi
			local executeCommand="$1" ; shift
		;;
	esac

	local argument
	local targetCommand="$( for argument in "$@" ; do printf '%q ' "$argument" ; done )"

	local sshTargets="$( \
		ListSshTargets --select-from-env \
			--line-prefix 'Prefix -3' \
			--line-suffix ' & ' \
			-T -o PreferredAuthentications=publickey -o ConnectTimeout=15 \
			$executeCommand $targetCommand \
		| cut -d" " -f 1,2,4-
	)"
	
	if [ "true" = "$explainTasks" ] && [ "$executeType" != "--display-targets" ] ; then
		echo "Will execute ($MDSC_CMD): " >&2
		local textLine
		echo "$sshTargets" | while read -r textLine ; do
			echo "  $textLine" >&2
		done
	fi

	case "$executeType" in
		--display-targets)
			echo "$sshTargets"
			return 0
		;;
		--execute-stdin)
			echo 
			echo "📝 ...Enter script and press CTRL+D to execute or press CTRL+C to cancel..." >&2
			echo 
			local executeCommand="`cat`"

			local sshTargets="$( echo "$sshTargets" | while read textLine ; do 
				echo '( echo "$executeCommand" | '${textLine%?}' ) &' 
			done )"

			printf "\n%s\n" \
				"📋 ...got command, executing..." \
				>&2
		;;
		--execute-script)
			local executeCommand="`cat "$executeScriptName"`"
			local sshTargets="$( echo "$sshTargets" | while read textLine ; do 
				echo '( echo "$executeCommand" | '${textLine%?}' ) &' 
			done )"
			
			if [ "true" = "$executeSleep" ] ; then
				printf "\n%s\n%s\n" \
					"📋 ...got command, executing..." \
					"⏳ ...sleeping for 5 seconds..." \
					>&2
				sleep 5
			else
				printf "\n%s\n" \
					"📋 ...got command, executing (--no-sleep)..." \
					>&2
			fi
			echo
		;;
		*)
			if [ "true" = "$executeSleep" ] ; then
				printf "\n%s\n" \
					"⏳ ...sleeping for 5 seconds..." \
					>&2
				sleep 5
			fi
		;;
	esac

	trap "trap - SIGTERM && kill -- -$$ >/dev/null 2>&1" SIGINT SIGTERM EXIT

	if [ -z "$executePostProcess" ] ; then
		eval $sshTargets
	else
		eval "( $sshTargets ) 2>&1 | $executePostProcess"
	fi
	wait
}

case "$0" in
	*/sh-scripts/ExecuteParallel.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ExecuteParallel.fn.sh <project-selector> --execute-stdin [<ssh arguments>...]" >&2
			echo "syntax: ExecuteParallel.fn.sh <project-selector> --execute-script <script-name> [<ssh arguments>...]" >&2
			echo "syntax: ExecuteParallel.fn.sh <project-selector> --execute-command <command> [<ssh arguments>...]" >&2
			echo "syntax: ExecuteParallel.fn.sh <project-selector> --display-targets [<ssh arguments>...]" >&2
			echo "syntax: ExecuteParallel.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MMDAPP/source/myx/myx.distro-source/sh-lib/HelpSelectProjects.include"
				echo "  Examples:" >&2
				echo "    ExecuteParallel.fn.sh --select-all --display-targets -l root" >&2
				echo "    ExecuteParallel.fn.sh --select-projects l6 --execute-stdin -l root" >&2
				echo "    ExecuteParallel.fn.sh --select-merged-keywords l6 --execute-stdin -l root" >&2
				echo "    ExecuteParallel.fn.sh --select-projects l6 -l root uname -a" >&2
				echo "    ExecuteParallel.fn.sh --select-projects l6 --ssh-user root uname -a" >&2
				echo "    ExecuteParallel.fn.sh --select-projects l6 --execute-command 'uname -a' -l root" >&2
				echo "    ExecuteParallel.fn.sh --select-all -l root myx.common install/myx.common-reinstall" >&2
				echo "    ExecuteParallel.fn.sh --select-all --execute-command 'myx.common install/myx.common-reinstall' -l root" >&2
				echo "    ExecuteParallel.fn.sh --select-provides 'deploy-ssh-target:' --execute-command 'myx.common install/myx.common-reinstall'" >&2
				echo "    ExecuteParallel.fn.sh --select-projects ndns- --execute-script source/ndm/cloud.all/setup.common-ndns/host/install/common-ndns-setup.txt -l root bash" >&2
			fi
			exit 1
		fi
		
		ExecuteParallel "$@"
	;;
esac
