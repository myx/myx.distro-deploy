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

ListSshTargets(){

	set -e

	local MDSC_CMD='ListSshTargets'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $(printf '%q ' "$@")" >&2

	case "$1" in
		''|--help|--help-syntax)
			echo "📘 syntax: ListSshTargets.fn.sh <project-selector> [--line-prefix <prefix>] [--line-suffix <suffix>] [<ssh arguments>...]" >&2
			echo "📘 syntax: ListSshTargets.fn.sh [--no-project-column] [--no-target-column] --all-targets [<ssh arguments>...]" >&2
			echo "📘 syntax: ListSshTargets.fn.sh [--line-prefix <prefix>] [--line-suffix <suffix>] --all-targets [<ssh arguments>...]" >&2
			echo "📘 syntax: ListSshTargets.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/help/HelpSelectProjects.include" >&2
				. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/help/Help.ListSshTargets.include" >&2
			fi
			return 0
		;;
	esac

	. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/SystemContext.UseStandardOptions.include"
	
	case "$1" in
		--all-targets|--line-*|--no-*-column|--ssh-*)
		;;
		--select-from-env)
			shift
			if [ -z "${MDSC_SELECT_PROJECTS:0:1}" ] ; then
				echo "⛔ ERROR: $MDSC_CMD: no projects selected!" >&2
				set +e ; return 1
			fi
		;;
		--*)
			Distro ListDistroProjects --select-execute-default ListSshTargets "$@"
			return 0
		;;
	esac

	local useSshHost="${useSshHost:-}" useSshPort="${useSshPort:-}" useSshUser="${useSshUser:-}" useSshHome="${useSshHome:-}" useSshArgs="${useSshArgs:-}"

	local linePrefix= lineSuffix= noProjectColumn= noTargetColumn=
	
	while true ; do
		case "$1" in
			--ssh-host) useSshHost="$2"; shift 2; continue; ;;
			--ssh-port) useSshPort="$2"; shift 2; continue; ;;
			--ssh-user) useSshUser="$2"; shift 2; continue; ;;
			--ssh-home) useSshHome="$2"; shift 2; continue; ;;
			--ssh-args) useSshArgs="$2"; shift 2; continue; ;;
			--all-targets)
				shift
				if [ -n "$1" ] ; then
					echo "$MDSC_CMD: no options allowed after --all-targets option ($MDSC_OPTION, $@)" >&2
					set +e ; return 1
				fi
				
				local setSshHost="${useSshHost:-}" setSshPort="${useSshPort:-}" setSshUser="${useSshUser:-}" setSshHome="${useSshHome:-}"
			
				Distro ListDistroProvides --select-all \
					--filter-own-provides-column "deploy-ssh-target:" \
					--add-merged-provides-column "deploy-ssh-client-settings:" \
				| DistroImageExtractSshConnections --line-prefix "$linePrefix" --line-suffix "$lineSuffix" $extraArguments
				return 0
			;;
			--line-prefix)
				linePrefix="$2"; shift 2
			;;
			--line-suffix)
				lineSuffix="$2"; shift 2
			;;
			--no-target-column)
				noTargetColumn="$1" ; shift
			;;
			--no-project-column)
				noProjectColumn="$1" ; shift
			;;
			*)
				local argument
				local extraArguments="$( for argument in "$@" ; do printf '%q ' "$argument" ; done )"
			
				local setSshHost="${useSshHost:-}" setSshPort="${useSshPort:-}" setSshUser="${useSshUser:-}" setSshHome="${useSshHome:-}"
			
				Distro ListDistroProvides --select-from-env \
					--filter-own-provides-column "deploy-ssh-target:" \
					--add-merged-provides-column "deploy-ssh-client-settings:" \
				| DistroImageExtractSshConnections --line-prefix "$linePrefix" --line-suffix "$lineSuffix" $noProjectColumn $noTargetColumn $extraArguments
				return 0
			;;
		esac
	done
}

case "$0" in
	*/sh-scripts/ListSshTargets.fn.sh)
		set -e 

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			ListSshTargets "${1:-"--help-syntax"}"
			exit 1
		fi
		
		ListSshTargets "$@"

		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			if [ "$1" = "--help" ] ; then
				. "$MDLT_ORIGIN/myx/myx.distro-system/sh-lib/help/HelpSelectProjects.include"
			fi
			exit 1
		fi
		
	;;
esac
