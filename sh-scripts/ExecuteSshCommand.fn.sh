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

Require ListSshTargets

ExecuteSshCommand(){

	. "$( myx.common which lib/prefix )"
	
	if [ "$1" == "--act" ] ; then
		shift
		set -e
		local sourceProject="$1" ; shift
		local targetCommand="$@" ; shift
		
		Prefix "$sourceProject" $targetCommand
		
		return 0
	fi
	
	local targetDescription
	
	eval $( ListSshTargets --line-prefix 'ExecuteSshCommand --act' --line-suffix ';' "$@" )
}

case "$0" in
	*/sh-scripts/ExecuteSshCommand.fn.sh)
		# ExecuteSshCommand.fn.sh  
		# ExecuteSshCommand.fn.sh --no-project
		# ExecuteSshCommand.fn.sh --no-target
		# ExecuteSshCommand.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ExecuteSshCommand.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ExecuteSshCommand.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ExecuteSshCommand.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ExecuteSshCommand.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ExecuteSshCommand.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait
		
		ExecuteSshCommand "$@"
	;;
esac