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

type DistroImage >/dev/null 2>&1 || \
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"

LocalTo(){

	set -e

	local MDSC_CMD='LocalTo'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

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

	local argument
	local extraArguments="$( for argument in "$@" ; do printf '%q ' "$argument" ; done )"
	local defaultCommand="`which bash || which sh`"
			
	local targets="$( 
		Distro ListSshTargets --select-projects "$filterProject" ${extraArguments:-$defaultCommand} 
	)"

	if [ -z "$targets" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2
		set +e ; return 1
	fi
	
	if [ "$targets" != "$( echo "$targets" | head -n 1 )" ] ; then
		echo "$MDSC_CMD: 🙋 STOP: More than one match: $@" >&2
		printf "Targets: \n%s\n" "$( echo "$targets" | sed -e 's|^|   |g' )" >&2
		set +e ; return 2
	fi

	local projectName="$(
		echo "$targets" \
		| while read -r projectName extraText ; do
			echo "$projectName"
		done
	)"

	local extraText="$(
		echo "$targets" \
		| while read -r projectName extraText ; do
			echo "$extraText"
		done
	)"

	(
		echo "$MDSC_CMD: Project-ID: $projectName" >&2
		echo "$MDSC_CMD: SshOptions: $extraText" >&2
		DistroSelectProject MDSC_PRJ_NAME "$projectName"
		export MDSC_PRJ_NAME="$MDSC_PRJ_NAME"
		set -x
		bash --rcfile "$MDLT_ORIGIN/myx/myx.distro-${MDSC_INMODE:-source}/sh-lib/console-${MDSC_INMODE:-source}-bashrc.rc" --noprofile
		#"$MMDAPP/actions/distro/source/console.sh" "$@"
	)
}

case "$0" in
	*/sh-scripts/LocalTo.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: LocalTo.fn.sh <project> [<ssh arguments>...]" >&2
			echo "📘 syntax: LocalTo.fn.sh <unique-project-name-part> [<ssh arguments>...]" >&2
			echo "📘 syntax: LocalTo.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    LocalTo.fn.sh ndss113" >&2
				echo "    LocalTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org" >&2
				echo "    LocalTo.fn.sh ndm/cloud.knt/setup.host-ndss112r3.example.org -l mysql whoami" >&2
			fi
			exit 1
		fi
		
		LocalTo "$@"
	;;
esac
