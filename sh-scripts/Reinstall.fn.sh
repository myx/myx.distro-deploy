#!/usr/bin/env bash



cat >/dev/null <<COMMENTS
#!/usr/bin/env bash
set -o errexit
set -o pipefail

# any broken pipe or ERR will kill *all* processes in our group
trap 'kill 0' SIGPIPE ERR

# ── your pipeline here ──
# as soon as one side dies (ssh exits, cat dies, etc),
# bash delivers SIGPIPE into the trap and kills everyone.
{ 
  echo echo hello
  # …your feeder… e.g. stty+read loop or cat …
  cat
} | ssh -tt host bash -i





Explanation:
kill 0 sends the signal to every process in the current process‐group (which by default includes all members of the pipeline).
We trap on SIGPIPE (raised when a write hits a closed pipe) and ERR (in case any builtin exits non-zero under errexit).
As soon as ssh (or your feeder) goes away, the trap fires and kills the remainder—no more “stuck cat waiting for a keystroke.”
If you only care about broken pipes (and not other errors), you can drop the ERR trap and just do:

trap 'kill 0' SIGPIPE

COMMENTS















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

Reinstall(){
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
			Reinstall --connect-ssh $sshTarget
			return 0
		fi
		
		echo "⛔ ERROR: Reinstall: More that one match: $@" >&2
		set +e ; return 1
	fi

	local filterProject="$1"
	if [ -z "$filterProject" ] ; then
		echo "⛔ ERROR: Reinstall: 'filterProject' argument (name or keyword or substring) is required!" >&2
		set +e ; return 1
	fi

	shift

	. "$(myx.common which lib/linesToArguments)"

	# set -x
	
	local targets="$( 
		Distro ListSshTargets --select-projects "$filterProject" "$@" \
		| LinesToArguments 
	)"

	# set +x

	if [ -z "$targets" ] ; then
		echo "⛔ ERROR: Reinstall: No matching projects with ssh deploy target is found, was looking for: $filterProject" >&2
		set +e ; return 1
	fi
	
	set -e
	eval Reinstall --check-count "$targets"
}

case "$0" in
	*/sh-scripts/Reinstall.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/help/Help.Reinstall.include"
			exit 1
		fi
		
		Reinstall "$@"
	;;
esac
