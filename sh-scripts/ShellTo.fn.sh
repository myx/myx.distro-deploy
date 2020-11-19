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

ShellTo(){
	if [ "--connect-ssh" = "$1" ] ; then
		shift
		set -e
		# set -x
		local sourceProject="$1" ; shift
		local targetCommand="$@"
		echo "Using Project: $sourceProject" >&2
		echo "Using Command: $targetCommand" >&2
		$targetCommand -t /bin/sh -i
		return 0
	fi
	
	if [ "--check-count" = "$1" ] ; then
		shift
		local sshTarget="$1"
		
		if [ -z "$2" ] ; then
			shift
			ShellTo --connect-ssh $sshTarget
			return 0
		fi
		
		echo "ERROR: ShellTo: More that one match: $@" >&2 ; return 1
	fi

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo "ERROR: ShellTo: 'filterProject' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	Require ListSshTargets
	. "`myx.common which lib/linesToArguments`"

	# set -x
	
	local targets="$( ListSshTargets --select-projects "$filterProject" "$@" | LinesToArguments )"

	# set +x

	if [ -z "$targets" ] ; then
		echo "ERROR: ShellTo: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2 ; return 1
	fi
	
	set -e
	eval ShellTo --check-count "$targets"
}

case "$0" in
	*/sh-scripts/ShellTo.fn.sh)
		# ShellTo.fn.sh  
		# ShellTo.fn.sh --no-project
		# ShellTo.fn.sh --no-target
		# ShellTo.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ShellTo.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ShellTo.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ShellTo.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ShellTo.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ShellTo.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait
		
		ShellTo "$@"
	;;
esac