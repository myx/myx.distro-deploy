#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "⛔ ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

type Prefix >/dev/null 2>&1 || \
	. "${MYXROOT:-/usr/local/share/myx.common}/bin/lib/prefix.Common"

ExecuteSequence(){

	set -e

	local MDSC_CMD='ExecuteSequence'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	if [ -z "$MDLT_ORIGIN" ] || ! type DistroDeployContext >/dev/null 2>&1 ; then
		. "${MDLT_ORIGIN:-$MMDAPP/.local}/myx/myx.distro-deploy/sh-lib/DeployContext.include"
		DistroSystemContext --distro-path-auto
	fi

	type DistroImage >/dev/null 2>&1 || \
		. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
	
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
			Distro ListDistroProjects --select-execute-default ExecuteSequence "$@"
			return 0
		;;
	esac

	local useSshHost="${useSshHost:-}" useSshPort="${useSshPort:-}" useSshUser="${useSshUser:-}" useSshHome="${useSshHome:-}"  useSshArgs="${useSshArgs:-}"

	local executeSleep="${executeSleep:-true}"
	local explainTasks="${explainTasks:-true}"

	while true ; do
		case "$1" in
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
				DistroDeployContext --parse-ssh-options "$1" "$2"; shift 2; continue
			;;
			--ssh-*)
				echo "$MDSC_CMD: ⛔ ERROR: invalid --ssh-XXXX option: $1" >&2
				set +e ; return 1
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

	local sshTargets="$(
		Distro ListSshTargets --select-from-env \
			--line-prefix '' \
			--line-suffix '' \
			-T -o PreferredAuthentications=publickey -o ConnectTimeout=15 \
			$executeCommand $targetCommand
	)"

	if [ "true" = "$explainTasks" ] && [ "$executeType" != "--display-targets" ] ; then
		echo "> 📋 $MDSC_CMD: Will execute: " >&2
		local project sshTarget sshOptions
		echo "$sshTargets" | while read -r project sshTarget sshOptions; do
			echo "  > $( basename "$project" ) $sshTarget $( DistroDeployContext --print-ssh-target $sshOptions 2>/dev/null )" >&2
		done \
		2>&1 | column -t 1>&2
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
			executeCommand="$(cat)"

			sshTargets="$( 
				local _ sshOptions
				echo "$sshTargets" | while read -r _ _ sshOptions ; do 
					echo 'echo "$executeCommand" | Prefix -o -3 DistroSshConnect '${sshOptions}
				done
			)"

			printf "\n%s\n" \
				"📋 ...got command, executing..." \
				>&2
		;;
		--execute-script)
			executeCommand="$(cat "$executeScriptName")"
			sshTargets="$( 
				local _ sshOptions
				echo "$sshTargets" | while read -r _ _ sshOptions ; do 
					echo 'echo "$executeCommand" | Prefix -o -3 DistroSshConnect '${sshOptions}' '
				done
			)"
			
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
			sshTargets="$( 
				local _ sshOptions
				echo "$sshTargets" | while read -r _ _ sshOptions ; do 
					echo 'Prefix -o -3 DistroSshConnect '${sshOptions}' '
				done
			)"
		;;
	esac

	eval "$sshTargets"
}

case "$0" in
	*/sh-scripts/ExecuteSequence.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/help/Help.ExecuteSequence.include"
			exit 1
		fi
		
		ExecuteSequence "$@"
	;;
esac
