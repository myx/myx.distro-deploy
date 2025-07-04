#!/usr/bin/env bash

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

Require ListDistroProvides
Require ListProjectProvides

if ! type DistroImage >/dev/null 2>&1 ; then
	. "$MDLT_ORIGIN/myx/myx.distro-deploy/sh-lib/lib.distro-image.include"
fi

##
## Internal - prints script files list using prepared variables
##
InstallPrepareScriptInternalPrintScriptFiles(){

	set -e

	local MDSC_CMD="InstallPrepareScript[--print-files]"
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	##
	## coarse-check parameters are legit
	##
	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project is not selected!" >&2
		set +e ; return 1
	fi

	local match
	( \
		ListProjectProvides "$MDSC_PRJ_NAME" --merge-sequence --filter-and-cut image-install:exec-update-before ;
		ListProjectProvides "$MDSC_PRJ_NAME" --merge-sequence --filter-and-cut image-install:exec-update-after | tail -r ;
	) \
	| while read -r sourceName scriptPath ; do
		local fileName="$MDSC_SOURCE/$sourceName/$scriptPath"
		if [ ! -f "$fileName" ] ; then
			echo "$MDSC_CMD: ⛔ ERROR: file is missing: $fileName" >&2; 
			set +e ; return 1
		fi
		if [ -n "$PROJECT_MATCH" ] && [ "" == "$( echo "$scriptPath" | grep $( for m in $PROJECT_MATCH ; do
			printf ' -e %q' "$m"
		done ) )" ] ; then
			[ -z "$MDSC_DETAIL" ] || echo "- $MDSC_CMD: skip (scripts filter): $sourceName/$scriptPath" >&2
			continue
		fi
		echo "$fileName"
	done
	return 0
}

##
## Internal - prints script using prepared variables
##
InstallPrepareScriptInternalPrintScript(){

	set -e

	local MDSC_CMD="InstallPrepareScript[--print-script]"
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2
	
	##
	## coarse-check parameters are legit
	##
	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project is not selected!" >&2
		set +e ; return 1
	fi

	local fileNames="$( InstallPrepareScriptInternalPrintScriptFiles )"
	if [ -z "$fileNames" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: no scripts selected!" >&2
		set +e ; return 1
	fi 

	echo "#!/bin/sh"
	echo "#*- 	"
	echo "#*- 	generated at: `date -u`"
	echo "#*- 	generated on: `hostname`"
	echo "#*- 	generated by: `whoami`"
	echo "#*- 	"
	echo "#*- 	generated for: $MDSC_PRJ_NAME"
	
	[ -z "$PROJECT_MATCH" ] || \
	echo "#*- 	script filter:" $PROJECT_MATCH
	
	echo "#*- 	"
	echo "#*- 	contents:"
	
	echo "$fileNames" \
	| while read -r fileName ; do
		echo "##**--     $fileName"
	done

	echo "#*- 	"
	echo
	echo

	##
	## set detailed logging on remote host
	##
	[ -z "$MDSC_DETAIL" ] || echo 'export MDSC_DETAIL=true'

	echo "export MDSC_PRJ_NAME='$MDSC_PRJ_NAME'"

	[ "full" != "$MDSC_DETAIL" ] || echo 'set -x'

	[ "none" == "$MDSC_DETAIL" ] || echo "echo '>> deploy script start, project: $MDSC_PRJ_NAME' >&2"

	DistroImageProjectContextVariables --install --export

	echo
	
	echo "$fileNames" \
	| while read -r fileName ; do
		local SC_HASH="BLK_$(cat "$fileName" | md5)"
		local SC_NAME="$(basename "$fileName")"
		echo
		echo "##**--  start, $fileName"
		echo
		[ "none" == "$MDSC_DETAIL" ] || echo "echo '>>> script start: $SC_NAME' >&2"
		#echo "$SC_HASH=\"\`"
		#echo "\`\""
		echo "( eval \"\$( cat << '$SC_HASH'"
			cat "$fileName"
			echo
			[ "none" == "$MDSC_DETAIL" ] || echo "echo '>>> script end: $SC_NAME' >&2"
		echo "$SC_HASH"
		echo ")\" )"
		[ "none" == "$MDSC_DETAIL" ] || echo "echo '>>> script done: $SC_NAME' >&2"
		echo
		echo "##**--  end, $fileName"
		echo
	done

	echo
	echo
	[ "none" == "$MDSC_DETAIL" ] || echo "echo '>> deploy script end, project: $MDSC_PRJ_NAME' >&2"
	echo "#*- 	EOF, generated for $MDSC_PRJ_NAME"

	return 0 
}

InstallPrepareScript(){

	set -e

	local MDSC_CMD='InstallPrepareScript'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	[ "full" != "$MDSC_DETAIL" ] || printf "| $MDSC_CMD: \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2
	
	local MDSC_PRJ_NAME="${MDSC_PRJ_NAME:-}"
	local PROJECT_MATCH="${PROJECT_MATCH:-}"
	
	while true ; do
		case "$1" in
			--project)
				shift ; DistroSelectProject MDSC_PRJ_NAME "$1" ; shift
			;;
			--match)
				shift ; PROJECT_MATCH="$PROJECT_MATCH $1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "$MDSC_CMD: ⛔ ERROR: project is not selected!" >&2
		set +e ; return 1
	fi

	case "$1" in
		--print-files)
			InstallPrepareScriptInternalPrintScriptFiles
			return 0 
		;;
		--print-install-context-variables)
			shift
			DistroImageProjectContextVariables --install "$@"
			return 0
		;;
		--print-script)
			InstallPrepareScriptInternalPrintScript
			return 0 
		;;
		--to-file)
			shift
			local targetFile="$1"
			if [ -z "$targetFile" ] ; then
				echo "$MDSC_CMD: 'targetFile' argument is required!" >&2
				set +e ; return 1
			fi
			
			InstallPrepareScriptInternalPrintScript > "$targetFile"
			return 0 
		;;
		*)
			echo "$MDSC_CMD: ⛔ ERROR: invalid option: $1" >&2
			set +e ; return 1
		;;
	esac
}

case "$0" in
	*/sh-scripts/InstallPrepareScript.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "📘 syntax: InstallPrepareScript.fn.sh --project <project> [--match <name>...] --print-files/--print-script" >&2
			echo "📘 syntax: InstallPrepareScript.fn.sh --project <project> [--match <name>...] --to-file <targetDirectory>" >&2
			echo "📘 syntax: InstallPrepareScript.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareScript.fn.sh --project ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz --print-script" >&2
				echo "    InstallPrepareScript.fn.sh --project ndm/cloud.knt/setup.host-ndss112r3.ndm9.xyz --match monit --print-script" >&2
				echo "    InstallPrepareScript.fn.sh --project prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --print-files" >&2
				echo "    InstallPrepareScript.fn.sh --project prv/cloud.mel/setup.host-l6b2h1.myx.co.nz --print-script" >&2
			fi
			exit 1
		fi
		
		InstallPrepareScript "$@"
	;;
esac
