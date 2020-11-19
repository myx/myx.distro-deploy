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

ConnectPort(){
	if [ "--connect-ssh" = "$1" ] ; then
		shift
		set -e
		set -x
		local sourceProject="$1" ; shift
		local targetCommand="$@"
		echo "Using Project: $sourceProject" >&2
		echo "Using Command: $targetCommand" >&2
		$targetCommand -N -T screen -s '$(which bash)' -q -O -U -D -R
		return 0
	fi
	
	if [ "--check-count" = "$1" ] ; then
		shift
		local sshTarget="$1" ; shift
		
		if [ -z "$1" ] ; then
			ConnectPort --connect-ssh $sshTarget
			return 0
		fi
		
		echo "ERROR: ConnectPort: More that one match: $@" >&2 ; return 1
	fi

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo "ERROR: ConnectPort: 'filterProject' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	Require ListSshTargets
	. "`myx.common which lib/linesToArguments`"

	# set -x
	
	local targets="$( ListSshTargets --select-projects "$filterProject" "$@" | LinesToArguments )"

	if [ -z "$targets" ] ; then
		echo "ERROR: ConnectPort: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2 ; return 1
	fi
	
	set -e
	eval ConnectPort --check-count $targets
}

case "$0" in
	*/sh-scripts/ConnectPort.fn.sh)
		# ConnectPort.fn.sh  
		# ConnectPort.fn.sh --no-project
		# ConnectPort.fn.sh --no-target
		# ConnectPort.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ConnectPort.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ConnectPort.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ConnectPort.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ConnectPort.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ConnectPort.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait
		
		ConnectPort "$@"
	;;
esac