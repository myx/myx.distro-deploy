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

Require ListDistroProvides

ListSshTargets(){
	
	[ -z "$MDSC_DETAIL" ] || echo "> ListSshTargets $@" >&2

	set -e

	case "$1" in
		--all-targets|--line-prefix|--line-suffix)
		;;
		--select-from-env)
			shift
			if [ -z "$MDSC_SELECT_PROJECTS" ] ; then
				echo "ERROR: ListSshTargets: no projects selected!" >&2
				return 1
			fi
		;;
		--*)
			Require ListDistroProjects
			ListDistroProjects --select-execute-default ListSshTargets "$@"
			return 0
		;;
	esac

	local useNoCache=""
	local useNoIndex=""

	local useSshHost="${useSshHost:-}"
	local useSshPort="${useSshPort:-}"
	local useSshUser="${useSshUser:-}"
	local useSshHome="${useSshHome:-}"

	local linePrefix=""
	local lineSuffix=""
	
	while true ; do
		case "$1" in
			--no-cache)
				shift ; local useNoCache="--no-cache"
			;;
			--no-index)
				shift ; local useNoIndex="--no-index"
			;;
			--ssh-host)
				shift ; useSshHost="$1" ; shift
			;;
			--ssh-port)
				shift ; useSshPort="$1" ; shift
			;;
			--ssh-user)
				shift ; useSshUser="$1" ; shift
			;;
			--ssh-home)
				shift ; useSshHome="$1" ; shift
			;;
			--all-targets)
				shift
				if [ ! -z "$1" ] ; then
					echo "ListSshTargets: no options allowed after --all-targets option ($MDSC_OPTION, $@)" >&2
					return 1
				fi
				
				ListDistroProvides --all-provides | grep 'deploy-ssh-target:' | sed 's|deploy-ssh-target:||' \
				| while read -r projectName sshTarget ; do
					local sshSpec="`echo "$sshTarget" | sed 's,^.*@,,'`"
					local sshUser="${useSshUser:-${sshTarget%${sshTarget%@$sshSpec}}}"
					local sshHost="${useSshHost:-`echo "$sshSpec"   | sed 's,:.*$,,'`}"
					local sshPort="${useSshPort:-`echo "$sshSpec"   | sed 's,^.*:,,'`}"
					printf '%s%s ssh %s -p %s -l %s %s%s\n' "$linePrefix" "$projectName" "$sshHost" "$sshPort" "${sshUser:-root}" "$extraArguments" "$lineSuffix"
				done
				return 0
			;;
			--line-prefix)
				shift
				local linePrefix="$1 " ; shift
			;;
			--line-suffix)
				shift
				local lineSuffix="$1" ; shift
			;;
			*)
				local extraArguments="$( for argument in "$@" ; do printf '%q ' "$argument" ; done )"
			
				ListDistroProvides --select-from-env | grep ' deploy-ssh-target:' | sed 's|deploy-ssh-target:||' \
				| while read -r projectName sshTarget ; do
					local sshSpec="`echo "$sshTarget" | sed 's,^.*@,,'`"
					local sshUser="${useSshUser:-${sshTarget%${sshTarget%@$sshSpec}}}"
					local sshHost="${useSshHost:-`echo "$sshSpec"   | sed 's,:.*$,,'`}"
					local sshPort="${useSshPort:-`echo "$sshSpec"   | sed 's,^.*:,,'`}"
					printf '%s%s ssh %s -p %s -l %s %s%s\n' "$linePrefix" "$projectName" "$sshHost" "$sshPort" "${sshUser:-root}" "$extraArguments" "$lineSuffix"
				done
				return 0
			;;
		esac
	done
}

case "$0" in
	*/sh-scripts/ListSshTargets.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListSshTargets.fn.sh [--line-prefix <prefix>] [--line-suffix <suffix>] --all-targets [<ssh arguments>...]" >&2
			echo "syntax: ListSshTargets.fn.sh <search> [--line-prefix <prefix>] [--line-suffix <suffix>] [<ssh arguments>...]" >&2
			echo "syntax: ListSshTargets.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --select-{all|sequence|changed|none} " >&2
				echo "    --{select|filter|remove}-{projects|[merged-]provides|[merged-]keywords} <glob>" >&2
				echo "    --{select|filter|remove}-repository-projects <repositoryName>" >&2
				echo "  Examples:" >&2
				echo "    ListSshTargets.fn.sh --all-targets" >&2

				echo "    ListSshTargets.fn.sh --select-projects l6" >&2
				echo "    ListSshTargets.fn.sh --select-keywords l6" >&2
				echo "    ListSshTargets.fn.sh --select-merged-keywords bhyve" >&2
				
				echo "    ListSshTargets.fn.sh --select-merged-keywords bhyve --filter-projects myx" >&2
				echo "    ListSshTargets.fn.sh --select-merged-keywords bhyve --remove-projects xyz" >&2
				
				echo "    ListSshTargets.fn.sh --select-projects l6 --line-prefix prefix --line-suffix suffix" >&2
				echo "    ListSshTargets.fn.sh --select-all --line-prefix '#' --line-suffix uname -l root" >&2
				
				echo '    ListSshTargets.fn.sh --select-projects l6 -l root' >&2
				echo '    ListSshTargets.fn.sh --select-all | cut -d" " -f2-' >&2
				echo '    ListSshTargets.fn.sh --select-all | cut -d" " -f2- -l root | ( while read -r sshCommand ; do $sshCommand 'uname -a' || true ; done )' >&2
				echo '    ListSshTargets.fn.sh --select-all | cut -d" " -f2- | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )' >&2
			fi
			exit 1
		fi
		
		ListSshTargets "$@"
	;;
esac