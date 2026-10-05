#!/usr/bin/env bash
## Behavioural check on the remote deploy script DeployProjectSsh.fn.sh generates: a failing exec script or a failing rsync ends the run
## non-zero with the failure named, without "task finished" or the "Settings applied" note. The lines the generator emits are taken from
## its own source, put into a small remote script with a fake rsync and a fake exec, and run. The control runs the same script built
## from the source with the status lines removed and must be caught. Offline: no ssh, no host, temp files only.
set -u
: "${MDLT_ORIGIN:?⛔ ERROR: MDLT_ORIGIN is not set}"
rigSource="$MDLT_ORIGIN/myx/myx.distro-deploy/sh-scripts/DeployProjectSsh.fn.sh"

rigRefuse(){
	echo "⛔ ERROR: $1 -- refusing to report a result" >&2 ; exit 1
}
[ -f "$rigSource" ] || rigRefuse "the generator is not at $rigSource"
rigTmp="$( mktemp -d -t ImageDeployRemoteStatusCheck.XXXXXX )" || exit 1
trap 'rm -rf -- "$rigTmp"' EXIT

rigPassCount=0
rigFailCount=0
rigAssert(){ ## what is asserted, got, want
	if [ "$2" = "$3" ] ; then
		printf '  PASS  %s\n' "$1" ; rigPassCount=$(( rigPassCount + 1 ))
	else
		printf '  FAIL  %s\n        got:  %s\n        want: %s\n' "$1" "$2" "$3" ; rigFailCount=$(( rigFailCount + 1 ))
	fi
}

## The two emitted line shapes, read out of the generator source and evaluated the way it evaluates them.
rigExecEcho="$( LC_ALL=C grep -m1 -F "echo 'bash ./exec" "$rigSource" )"
rigRsyncEcho="$( LC_ALL=C grep -m1 -F 'mdscRsyncRc=' "$rigSource" )"
[ -n "$rigExecEcho" ] || rigRefuse "no line of the generator emits the exec call"
rigExecLine="$( eval "${rigExecEcho#"${rigExecEcho%%echo*}"}" )"
sourcePath=os-commands
rigRsyncLine=""
[ -z "$rigRsyncEcho" ] || rigRsyncLine="$( eval "${rigRsyncEcho#"${rigRsyncEcho%%echo*}"}" )"

## One remote script around those lines, run in a directory holding the fake rsync and exec.
rigRun(){ ## name, exec exit, rsync exit, exec line, rsync line
	local runDir="$rigTmp/$1"
	mkdir -p "$runDir/bin"
	printf '#!/bin/sh\nexit %s\n' "$3" > "$runDir/bin/rsync"
	printf 'exit %s\n' "$2" > "$runDir/exec"
	chmod +x "$runDir/bin/rsync"
	{
		printf '%s\n' '#!/bin/sh' 'echo "ImageDeploy: syncing files..." >&2'
		printf '%s\n' "rsync -i a b 2>&1 | ( grep --line-buffered -v zzz 2>&1 | tee -a host-files-rsync.log >&2 || : )"
		printf '%s\n' "$5"
		printf '%s\n' 'echo "ImageDeploy: executing scripts..." >&2' "$4"
		printf '%s\n' 'echo "ImageDeploy: task finished." >&2' 'echo "Settings applied"' 'exit 0'
	} > "$runDir/remote.sh"
	( cd "$runDir" && PATH="$runDir/bin:$PATH" bash ./remote.sh > out 2> err ) ; printf '%s' "$?" > "$runDir/rc"
}
rigHas(){ ## file, text
	LC_ALL=C grep -q -F -- "$2" "$1" && printf yes || printf no
}

echo "-- the generated lines hold up --"
rigRun ok 0 0 "$rigExecLine" "$rigRsyncLine"
rigAssert "everything succeeds: exit 0"                   "$( cat "$rigTmp/ok/rc" )" 0
rigAssert "and the task finishes"                         "$( rigHas "$rigTmp/ok/err" 'task finished' )" yes
rigRun execfail 3 0 "$rigExecLine" "$rigRsyncLine"
rigAssert "a failing exec script: its own exit status"    "$( cat "$rigTmp/execfail/rc" )" 3
rigAssert "the failure is named"                          "$( rigHas "$rigTmp/execfail/err" 'ImageDeploy: ⛔ ERROR: the exec script failed (exit 3)' )" yes
rigAssert "no task finished"                              "$( rigHas "$rigTmp/execfail/err" 'task finished' )" no
rigAssert "no Settings applied note"                      "$( rigHas "$rigTmp/execfail/out" 'Settings applied' )" no
rigRun rsyncfail 0 23 "$rigExecLine" "$rigRsyncLine"
rigAssert "a failing rsync: exit 1"                       "$( cat "$rigTmp/rsyncfail/rc" )" 1
rigAssert "the failure is named with its exit status"     "$( rigHas "$rigTmp/rsyncfail/err" 'ImageDeploy: ⛔ ERROR: rsync of os-commands failed (exit 23)' )" yes
rigAssert "no task finished after it"                     "$( rigHas "$rigTmp/rsyncfail/err" 'task finished' )" no
rigAssert "no Settings applied note after it"             "$( rigHas "$rigTmp/rsyncfail/out" 'Settings applied' )" no

echo "-- control: the old generator text is caught --"
rigRun oldexec 3 0 "bash ./exec" ""
rigAssert "old exec line: the failed run still reports finished" "$( rigHas "$rigTmp/oldexec/err" 'task finished' )" yes
rigAssert "old exec line: and exits 0"                    "$( cat "$rigTmp/oldexec/rc" )" 0
rigRun oldrsync 0 23 "bash ./exec" ""
rigAssert "old rsync handling: a failed rsync still exits 0" "$( cat "$rigTmp/oldrsync/rc" )" 0

if [ "$rigFailCount" -ne 0 ] ; then
	echo "⛔ IMAGE DEPLOY REMOTE STATUS CHECK FAILED: $rigFailCount of $(( rigPassCount + rigFailCount )) assertion(s)" >&2 ; exit 1
fi
printf 'IMAGE_DEPLOY_REMOTE_STATUS: OK (%d assertions, offline)\n' "$rigPassCount"
