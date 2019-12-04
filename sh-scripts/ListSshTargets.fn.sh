#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-source/sh-lib/DistroShellContext.include"
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
			local sshHost="`echo "$sshTarget" | sed 's,/.*$,,'`"
			local sshPort="`echo "$sshTarget" | sed 's,^.*/,,'`"
			printf 'ssh %s -p %s ' "$sshHost" "$sshPort"
		fi
		echo -n "$extraArguments"
		[ -z "$lineSuffix" ] || printf '%s ' "$lineSuffix"
		echo
		return 0
	fi
	local linePrefix=""
	local lineSuffix=""
	local noTarget=""
	local noProject=""
	
	local filterProjects=""
	
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
			--filter-projects)
				shift
				filterProjects="$filterProjects --filter-projects $1" ; shift
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
			ListDistroProvides $filterProjects | grep 'deploy-ssh-target\\:' | sed 's|deploy-ssh-target\\:||' \
				| myx.common lib/linesToArguments \
		)
}

case "$0" in
	*/sh-scripts/ListSshTargets.fn.sh)
		# ListSshTargets.fn.sh  
		# ListSshTargets.fn.sh --no-project
		# ListSshTargets.fn.sh --no-target
		# ListSshTargets.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# ListSshTargets.fn.sh --no-project -l root | ( while read -r sshCommand ; do $sshCommand 'uname -a' ; done )
		# source "`myx.common which lib/prefix`" ;  ListSshTargets.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		
		ListSshTargets "$@"
	;;
esac