#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

Require ListDistroProvides

ListSshTargets(){

	if [ "--internal-all-lines" = "$1" ] ; then
		shift
		while [ "" != "$1" ] ; do
			ListSshTargets --internal-print-line $1
			shift
		done
		return 0
	fi
	if [ "--internal-print-line" = "$1" ] ; then
		shift
		local projectName="$1" ; shift
		local sshTarget="$1" ; shift
		[ -z "$linePrefix" ] || printf '%s ' "$linePrefix"
		[ ! -z "$noProject" ] || printf '%s ' "$projectName"
		if [ -z "$noTarget" ] ; then
			local sshHost="`echo "$sshTarget" | sed 's,:.*$,,'`"
			local sshPort="`echo "$sshTarget" | sed 's,^.*:,,'`"
			printf 'ssh %s -p %s ' "$sshHost" "$sshPort"
		fi
		echo -n "$extraArguments"
		[ -z "$lineSuffix" ] || printf '%s ' "$lineSuffix"
		echo
		return 0
	fi

	set -e

	local filterProjects=""

	while true ; do
		case "$1" in
			--all)
				shift
				local filterProjects="$filterProjects --all"
				break
			;;
			--filter-projects)
				shift
				local filterProjects="$filterProjects --filter-projects $1" ; shift
			;;
			--filter-keywords)
				shift
				local filterProjects="$filterProjects --filter-keywords $1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$filterProjects" ] ; then
		echo "ERROR: ListSshTargets: 'filterProjects' argument (name or keyword or substring) is required!" >&2
		return 1
	fi

	local linePrefix=""
	local lineSuffix=""
	local noTarget=""
	local noProject=""
	
	while true ; do
		case "$1" in
			--line-prefix)
				shift
				local linePrefix="$1" ; shift
				;;
			--line-suffix)
				shift
				local lineSuffix="$1" ; shift
				;;
			--no-target)
				shift
				local noTarget="true"
				;;
			--no-project)
				shift
				local noProject="true"
				;;
			*)
				break
				;;
		esac
	done


	local extraArguments="$(for argument in "$@" ; do 
		printf '%q ' "$argument" 
	done)"


	
	eval ListSshTargets --internal-all-lines $( \
			ListDistroProvides $filterProjects | grep 'deploy-ssh-target:' | sed 's|deploy-ssh-target:||' \
				| myx.common lib/linesToArguments \
		)
}

case "$0" in
	*/sh-scripts/ListSshTargets.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: ListSshTargets.fn.sh <search> [--no-project/--no-target] [<ssh arguments>...]" >&2
			echo "syntax: ListSshTargets.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Search:" >&2
				echo "    --all / --filter-projects <glob> / --filter-keywords <keyword>" >&2
				echo "  Examples:" >&2
				echo "    ListSshTargets.fn.sh --filter-projects l6" >&2
				echo "    ListSshTargets.fn.sh --filter-keywords l6" >&2
				echo "    ListSshTargets.fn.sh --filter-projects l6 --no-target" >&2
				echo "    ListSshTargets.fn.sh --filter-projects l6 -l root" >&2
				echo "    ListSshTargets.fn.sh --filter-projects l6 --no-project -l root" >&2
				echo "    ListSshTargets.fn.sh --all --no-project" >&2
				echo "    ListSshTargets.fn.sh --all --no-project -l root | ( while read -r sshCommand ; do $sshCommand 'uname -a' || true ; done )" >&2
				echo "    ListSshTargets.fn.sh --all --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )" >&2
				echo "    source "`myx.common which lib/prefix`" ;  ListSshTargets.fn.sh --all --no-project | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & done ; wait )" >&2
			fi
			exit 1
		fi
		
		ListSshTargets "$@"
	;;
esac