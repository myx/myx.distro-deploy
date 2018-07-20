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

	typeLine(){
		local projectName="$1" ; shift
		local sshTarget="$1" ; shift
		[ -z "$linePrefix" ] || printf '%s ' "$linePrefix"
		[ ! -z "$noProject" ] || printf '%s ' "$projectName"
		if [ -z "$noTarget" ] ; then
			local sshHost="`echo "$sshTarget" | sed 's,/.*$,,'`"
			local sshPort="`echo "$sshTarget" | sed 's,^.*/,,'`"
			printf 'ssh %s -p %s ' "$sshHost" "$sshPort"
		fi
		echo -n "$@"
		[ -z "$lineSuffix" ] || printf '%s ' "$lineSuffix"
		echo
	}

	ListDistroProvides | grep 'deploy-ssh-target\\:' | sed 's|deploy-ssh-target\\:||' \
	| while read LINE ; do
		typeLine $LINE "$@" 
	done
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