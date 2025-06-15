#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if [ -z "$MDLT_ORIGIN" ] || ! type DistroSystemContext >/dev/null 2>&1 ; then
	. "${MDLT_ORIGIN:=$MMDAPP/.local}/myx/myx.distro-system/sh-lib/SystemContext.include"
	DistroSystemContext --distro-path-auto
fi

Require ListProjectProvides

DeployProjectSsh(){
	if [ ! -d "$MMDAPP/output" ] ; then
		if [ ! -d "$MMDAPP/source" ] ; then
			echo "ERROR: DeploySettings: output folder does not exist: $MMDAPP/output" >&2
			set +e ; return 1
		fi
	fi

	
	[ -z "$MDSC_DETAIL" ] || echo "> DeploySettings $@" >&2

	set -e

	case "$1" in
		--project)
		;;
		--explicit-noop)
			shift
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "ERROR: DeploySettings: --select-from-env no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--set-env)
			shift
			if [ -z "$1" ] ; then
				echo "ERROR: DeploySettings: --set-env argument expected!" >&2
				set +e ; return 1
			fi
			local envName="$1" ; shift
			eval "$envName='` DeploySettings --explicit-noop "$@" `'"
			return 0
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default DeployProjectSsh "$@"
			return 0
		;;
	esac

	local doFiles="auto" doScripts="auto"
	
	while true ; do
		case "$1" in
			--do-exec)
				shift ;	local doScripts="true"
			;;
			--no-exec)
				shift ;	local doScripts=""
			;;
			--do-sync)
				shift ;	local doFiles="true"
			;;
			--no-sync)
				shift ;	local doFiles=""
			;;
			--do-none)
				shift ; local doScripts="" doFiles=""
			;;
			--do-full|--do-both)
				shift ; local doScripts="true" doFiles="true"
			;;
			--print-folders)
				shift
				if [ -n "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-folders option ($@)" >&2
					set +e ; return 1
				fi
				set +e ; return 1
			;;
			--print-files)
				shift
				if [ -n "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-files option ($@)" >&2
					set +e ; return 1
				fi
				local outputPath="$MMDAPP/output/deploy/$projectName/sync"
				if [ "true" = "$doFiles" ] || [ "auto" = "$doFiles" -a  ! -d "$outputPath"  ] ; then
					require InstallPrepareFiles
					InstallPrepareFiles --project "$projectName" --to-directory "$outputPath"
				fi
				if [ ! -d "$outputPath" ] ; then
					echo "ERROR: DeployProjectSsh: no sync folder found ($outputPath)" >&2
					set +e ; return 1
				fi
				find "$outputPath" -type f | sed "s|^$outputPath/||"
				return 0
			;;
			--print-sync-tasks)
				shift
				if [ -n "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-sync-tasks option ($@)" >&2
					set +e ; return 1
				fi
				set +e ; return 1
			;;
			--deploy-rsync-direct|--deploy-script-rsync)
				set +e ; return 1
			;;
			--print-installer)
				shift
				if [ -n "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-installer option ($@)" >&2
					set +e ; return 1
				fi
				local outputPath="$MMDAPP/output/deploy/$projectName/exec"
				if [ "true" = "$doScripts" ] || [ "auto" = "$doScripts" -a  ! -f "$outputPath"  ] ; then
					Require InstallPrepareScript
					InstallPrepareScript --project "$projectName" --to-file "$outputPath"
				fi
				if [ ! -f "$outputPath" ] ; then
					echo "ERROR: DeployProjectSsh: no installer script found ($outputPath)" >&2
					set +e ; return 1
				fi
				cat "$outputPath"
				return 0
			;;
			--print-ssh-target)
				shift
				if [ -n "$1" ] ; then
					echo "ERROR: DeployProjectSsh: no options allowed after --print-ssh-target option ($@)" >&2
					set +e ; return 1
				fi
				ListProjectProvides "$projectName" --print-provides-only | grep 'deploy-ssh-target:' | sed 's|deploy-ssh-target:||' | while read -r sshTarget ; do
					local sshHost="`echo "$sshTarget" | sed 's,:.*$,,'`"
					local sshPort="`echo "$sshTarget" | sed 's,^.*:,,'`"
					printf 'ssh %s -p %s\n' "$sshHost" "$sshPort"
				done
				return 0
			;;
			'')
				echo "ERROR: DeployProjectSsh: --do-XXXX option must be specified" >&2
				set +e ; return 1
			;;
			*)
				echo "ERROR: DeployProjectSsh: invalid option: $1" >&2
				set +e ; return 1
			;;
		esac
	done

	# ssh $sshHost -p $sshPort "$@"
}

case "$0" in
	*/sh-scripts/DeployProjectSsh.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: DeployProjectSsh.fn.sh <project> --do-exec/--do-sync/--do-both/--do-none" >&2
			echo "syntax: DeployProjectSsh.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    DeployProjectSsh.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
			fi
			exit 1
		fi
		
		DeployProjectSsh "$@"
	;;
esac
