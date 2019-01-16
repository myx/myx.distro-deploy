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

ScreenTo(){
	if [ "--connect-ssh" = "$1" ] ; then
		shift
		set -e
		# set -x
		local sourceProject="$1" ; shift
		local targetCommand="$@"
		echo "Using Project: $sourceProject" >&2
		echo "Using Command: $targetCommand" >&2
		$targetCommand -t '
			test -x "`which screen`" && screen -s sh -q -O -U -D -R 
			test ! -x "`which screen`" && sh 
		'
		return 0
	fi
	
	if [ "--check-count" = "$1" ] ; then
		shift
		local sshTarget="$1"
		
		if [ -z "$2" ] ; then
			shift
			ScreenTo --connect-ssh $sshTarget
			return 0
		fi
		
		echo "ERROR: ScreenTo: More that one match: $@" >&2 ; return 1
	fi

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo "ERROR: ScreenTo: 'filterProject' argument (name or keyword or substring) is required!" >&2 ; return 1
	fi

	shift

	Require ListSshTargets
	. "`myx.common which lib/linesToArguments`"

	# set -x
	
	local targets="$( ListSshTargets --filter-projects "$filterProject" "$@" | LinesToArguments )"

	# set +x

	if [ -z "$targets" ] ; then
		echo "ERROR: ScreenTo: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2 ; return 1
	fi
	
	set -e
	eval ScreenTo --check-count "$targets"
}

case "$0" in
	*/sh-scripts/ScreenTo.fn.sh)
		# ScreenTo.fn.sh  
		# ScreenTo.fn.sh --no-project
		# ScreenTo.fn.sh --no-target
		# ScreenTo.fn.sh --select-keyword ndss --intersect-keyword ndns --remove-keyword live -l root 'myx.common install/updates'
		#
		# ScreenTo.fn.sh --no-project | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' & wait ; done )
		# source "`myx.common which lib/prefix`" ; ScreenTo.fn.sh --no-project -l root | ( while read -r sshCommand ; do Prefix -2 $sshCommand 'uname -a' ; done )
		# ScreenTo.fn.sh --no-project -l root | ( source "`myx.common which lib/async`" ;  while read -r sshCommand ; do Async -2 $sshCommand 'uname -a' ; wait ; done )
		# ScreenTo.fn.sh --no-project -l root | ( source "`myx.common which lib/prefix`" ;  while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait )
		# source "`myx.common which lib/prefix`" ;  ScreenTo.fn.sh --no-project -l root | while read -r sshCommand ; do Prefix -2 $sshCommand 'whoami' & done ; wait
		
		ScreenTo "$@"
	;;
esac