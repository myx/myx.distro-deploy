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

if ! type DistroImage >/dev/null 2>&1 ; then
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"
fi

ShellTo(){

	local MDSC_CMD='ShellTo'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	set -e

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"

	local useSshHost="${useSshHost:-}"
	local useSshPort="${useSshPort:-}"
	local useSshUser="${useSshUser:-}"
	local useSshHome="${useSshHome:-}"

	while true ; do
		case "$1" in
			--ssh-name|--ssh-host|--ssh-port|--ssh-user|--ssh-home|--ssh-args)
				DistroImageParseSshOptions "$1" "$2"
				shift 2
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

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo -e "$MDSC_CMD: ⛔ ERROR: 'filterProject' argument (name or keyword or substring) is required!" >&2
		set +e ; return 1
	fi

	shift

	Require ListSshTargets

	local argument
	local extraArguments="$( for argument in "$@" ; do printf '%q ' "$argument" ; done )"
	local defaultCommand="-t '\`command -v bash || command -v sh\`'"
			
	local targets="$( ListSshTargets --select-projects "$filterProject" ${extraArguments:-$defaultCommand} | cut -d" " -f 2- )"

	if [ -z "$targets" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2
		set +e ; return 1
	fi
	
	if [ "$targets" != "$( echo "$targets" | head -n 1 )" ] ; then
		echo "$MDSC_CMD: 🙋 STOP: More than one match: $@" >&2
		printf "Targets: \n%s\n" "$( echo "$targets" | sed -e 's|^|   |g' )" >&2
		set +e ; return 2
	fi

	set -e
	echo "$MDSC_CMD: Using Command: $targets" >&2
	eval "$targets"
}

case "$0" in
	*/sh-scripts/ShellTo.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: ShellTo.fn.sh <project> [<ssh arguments>...]" >&2
			echo "📘 syntax: ShellTo.fn.sh <unique-project-name-part> [<ssh arguments>...]" >&2
			echo "📘 syntax: ShellTo.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    ShellTo.fn.sh ndss113" >&2
				echo "    ShellTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz" >&2
				echo "    ShellTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz -l mysql whoami" >&2
			fi
			exit 1
		fi
		
		ShellTo "$@"
	;;
esac
