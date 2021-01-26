#!/usr/bin/env bash

if [ -z "$MMDAPP" ] ; then
	set -e
	export MMDAPP="$( cd $(dirname "$0")/../../../.. ; pwd )"
	echo "$0: Working in: $MMDAPP"  >&2
	[ -d "$MMDAPP/source" ] || ( echo "ERROR: expecting 'source' directory." >&2 && exit 1 )
fi

if ! type DistroShellContext >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/DistroShellContext.include"
	DistroShellContext --distro-path-auto
fi

if ! type ImagePrepare >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/lib.image-prepare.include"
fi

InstallPrepareFiles(){

	set -e

	local MDSC_CMD='InstallPrepareFiles'
	[ -z "$MDSC_DETAIL" ] || echo "> $MDSC_CMD $@" >&2

	# [ -z "$MDSC_DETAIL" ] || printf "| $MDSC_CMD: \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2
	
	local MDSC_PRJ_NAME="${MDSC_PRJ_NAME:-}"
	
	while true ; do
		case "$1" in
			--project)
				shift ; DistroSelectProject MDSC_PRJ_NAME "$1" ; shift
			;;
			*)
				break
			;;
		esac
	done

	if [ -z "$MDSC_PRJ_NAME" ] ; then
		echo "ERROR: $MDSC_CMD: project is not selected!" >&2
		return 1
	fi

	case "$1" in
		--print-sync-folders)
			ImagePrepareProjectSyncFolders
			return 0
		;;
		--print-clone-files)
			ImagePrepareProjectCloneFiles
			return 0
		;;
		--print-source-patch-scripts)
			ImagePrepareProjectSourcePatchScripts
			return 0
		;;
		--print-target-patch-scripts)
			ImagePrepareProjectTargetPatchScripts
			return 0
		;;
		--to-directory)
			shift
		 	local targetPath="$1" ; shift
			if [ -z "$targetPath" ] ; then
				echo "ERROR: $MDSC_CMD: 'targetDirectory' (or --no-write)  argument is required!" >&2
				return 1
			fi

			local allSyncFolders="$( ImagePrepareProjectSyncFolders )"
			local allSourceScripts="$( ImagePrepareProjectSourcePatchScripts )"
			local allCloneFiles="$( ImagePrepareProjectCloneFiles )"
			local allTargetScripts="$( ImagePrepareProjectTargetPatchScripts )"
			
			##
			## sync files from source to output
			##
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: sync files from source to output" >&2
			local sourceName sourcePath mergePath
			[ -z "${allSyncFolders:0:1}" ] || echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				mkdir -p "$targetPath/$mergePath"
				rsync -rt --chmod=ug+rw --omit-dir-times "$MDSC_SOURCE/$sourceName/$sourcePath/" "$targetPath/$mergePath/"
			done

			##
			## execute path-related patches before processing files
			##
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: execute path-related patches before processing files" >&2
			[ -z "${allSyncFolders:0:1}" ] || echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				local matchSourceName sourcePath scriptSourceName scriptName
				[ -z "${allSourceScripts:0:1}" ] || echo "$allSourceScripts" | grep -e "^$sourceName " | cut -d" " -f2- \
				| while read -r matchSourcePath scriptSourceName scriptName ; do
					case "${matchSourcePath##/}/" in
						"${sourcePath##/}/"*)
							[ -z "$MDSC_DETAIL" ] || echo "= $MDSC_CMD: path matched: $matchSourcePath ?= $sourcePath" >&2
							echo "$scriptSourceName" "$scriptName" "${mergePath%/}/${matchSourcePath#${sourcePath%/}}"
							continue
						;;
					esac
				done
			done \
			| awk '!x[$0]++' \
			| while read -r scriptSourceName scriptName mergePath; do
				[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: exec: image-prepare:source-patch:script: $scriptSourceName:$scriptFile:$mergePath" >&2
				[ -z "$MDSC_DETAIL" ] || echo "echo '> run: $scriptSourceName:$scriptFile:$mergePath' >&2"
				if ! ( cd "$targetPath/$mergePath" ; . "$MMDAPP/source/$scriptSourceName/$scriptName" ) ; then
					echo "ERROR: $MDSC_CMD: error running patch script: $scriptSourceName/$scriptName" >&2; 
				fi
				[ -z "$MDSC_DETAIL" ] || echo "echo '< run: $scriptSourceName:$scriptFile:$mergePath' >&2"
			done

			##
			## clone/multiply files
			##
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: clone/multiply files" >&2
			local sourceName sourcePath mergePath
			[ -z "${allSyncFolders:0:1}" ] || echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				local targetFullPath="$targetPath/${mergePath##/}"
			
				local sourceName cloneSourcePath sourceFileName targetFileName
				[ -z "${allCloneFiles:0:1}" ] || echo "$allCloneFiles" | grep "^$sourceName $sourcePath " \
				| while read -r sourceName cloneSourcePath sourceFileName targetFileName ; do
					rsync -rt --chmod=ug+rw "$targetFullPath/${cloneSourcePath##$sourcePath}/$sourceFileName" "$targetFullPath/$targetFileName"
				done
			done

			##
			## execute path-related patches after processing files
			##
			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: execute path-related patches after processing files" >&2
			local sourceName sourcePath mergePath
			local scriptSourceName scriptName matchTargetPath
			[ -z "${allSyncFolders:0:1}" ] || echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				[ -z "${allTargetScripts:0:1}" ] || echo "$allTargetScripts" \
				| while read -r scriptSourceName scriptName matchTargetPath; do
					case "$matchTargetPath" in
						*'*')
							local globTargetPath="${matchTargetPath%'*'}"
							case "${mergePath%/}/" in
								"${globTargetPath%/}/"*)
									[ -z "$MDSC_DETAIL" ] || echo "= $MDSC_CMD: path matched: $matchTargetPath ?= $mergePath" >&2
									echo "$scriptSourceName" "$scriptName" "${mergePath%/}"
									continue
								;;
							esac
						;;
						'*'*)
							echo "$MDSC_CMD: suffix search is not supported!" >&2
							return 1
						;;
						*)
							case "${matchTargetPath%/}/" in
								"${mergePath%/}/"*)
									[ -z "$MDSC_DETAIL" ] || echo "= $MDSC_CMD: path matched: $matchTargetPath ?= $mergePath" >&2
									echo "$scriptSourceName" "$scriptName" "${mergePath%/}${matchTargetPath#${mergePath%/}}"
									continue
								;;
							esac
						;;
					esac
				done
			done \
			| awk '!x[$0]++' \
			| while read -r scriptSourceName scriptName mergePath; do
				[ -z "$MDSC_DETAIL" ] || echo "$MDSC_CMD: exec: image-prepare:target-patch:script: $scriptSourceName:$scriptFile:$mergePath" >&2
				[ -z "$MDSC_DETAIL" ] || echo "echo '> run: $scriptSourceName:$scriptFile:$mergePath' >&2"
				if ! ( cd "$targetPath/$mergePath" ; . "$MMDAPP/source/$scriptSourceName/$scriptName" ) ; then
					echo "ERROR: $MDSC_CMD: error running patch script: $scriptSourceName/$scriptName" >&2; 
				fi
				[ -z "$MDSC_DETAIL" ] || echo "echo '< run: $scriptSourceName:$scriptFile:$mergePath' >&2"
			done

			[ -z "$MDSC_DETAIL" ] || echo "| $MDSC_CMD: done." >&2
			return 0
		;;
		--to-temp)
			shift
			local tempDirectory="`mktemp -d -t "MDSC_IPF"`"
			local saveDirectory="`pwd`"
			trap "cd '$saveDirectory' ; rm -rf '$tempDirectory'" EXIT
			echo "$MDSC_CMD: using temp: $tempDirectory" >&2
			InstallPrepareFiles --to-directory "$tempDirectory"
			echo "$MDSC_CMD: temp prepared" >&2

			cd "$tempDirectory"
			
			if [ -z "$1" ] ; then
				find "." -type f | sort
				return 0 
			fi
			 
			eval "$@"
			return 0 
		;;
		--to-deploy-output)
			if [ ! -d "$MMDAPP/output" ] ; then
				echo "ERROR: $MDSC_CMD: deploy-output directory is missing: $MMDAPP/output" >&2; 
				return 1
			fi
			InstallPrepareFiles --to-directory "$MMDAPP/output/deploy/$MDSC_PRJ_NAME"
			return 0
		;;
	esac

}

case "$0" in
	*/sh-scripts/InstallPrepareFiles.fn.sh)
		if [ -z "$1" ] || [ "$1" = "--help" ] ; then
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --print-sync-folders/--print-clone-files" >&2
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --to-temp <command> [<argument...>]" >&2
			echo "syntax: InstallPrepareFiles.fn.sh --project <project> --to-directory <targetDirectory>" >&2
			echo "syntax: InstallPrepareFiles.fn.sh [--help]" >&2
			if [ "$1" = "--help" ] ; then
				echo "  Examples:" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-sync-folders" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-clone-files" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-source-patch-scripts" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --print-target-patch-scripts" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp find . | sort | grep web/default" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp 'pwd ; find . | sort'" >&2
				echo "    InstallPrepareFiles.fn.sh --project ndm/cloud.dev/setup.host-ndns001.ndm9.xyz --to-temp tar czvf - . > /dev/null" >&2
			fi
			exit 1
		fi
		
		InstallPrepareFiles "$@"
	;;
esac