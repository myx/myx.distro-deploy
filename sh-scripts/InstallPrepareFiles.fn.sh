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

# Require ListDistroProvides
# Require ListProjectSequence
# Require ListProjectProvides
# Require ListDistroProjects

if ! type ImagePrepare >/dev/null 2>&1 ; then
	. "$MMDAPP/source/myx/myx.distro-deploy/sh-lib/lib.image-prepare.include"
fi

InstallPrepareFiles(){

	set -e

	[ -z "$MDSC_DETAIL" ] || echo "> InstallPrepareFiles $@" >&2
	# [ -z "$MDSC_DETAIL" ] || printf "| InstallPrepareFiles: \n\tSOURCE: $MDSC_SOURCE\n\tCACHED: $MDSC_CACHED\n\tOUTPUT: $MDSC_OUTPUT\n" >&2
	
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
		echo "ERROR: InstallPrepareFiles: project is not selected!" >&2
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
				echo "ERROR: InstallPrepareFiles: 'targetDirectory' (or --no-write)  argument is required!" >&2
				return 1
			fi

			local allSyncFolders="$( ImagePrepareProjectSyncFolders )"
			local allCloneFiles="$( ImagePrepareProjectCloneFiles )"
			
			echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				local sourceFullPath="$MDSC_SOURCE/$sourceName/$sourcePath"
				local targetFullPath="$targetPath/$mergePath"
				mkdir -p "$targetFullPath"
				rsync -rt --chmod=ug+rw --omit-dir-times "$sourceFullPath/" "$targetFullPath/"
			done

			#echo "$allSyncFolders" \
			#| while read -r sourceName sourcePath mergePath ; do
			#	local sourceFullPath="$MDSC_SOURCE/$sourceName/$sourcePath"
			#	local targetFullPath="$targetPath/$mergePath"
			#
			#	echo "$allCloneFiles" | grep "^$sourceName $sourcePath " \
			#	| while read -r sourceName sourcePath sourceFileName targetFileName ; do
			#		rsync -rt --chmod=ug+rw "$sourceFullPath/$sourceFileName" "$targetFullPath/$targetFileName"
			#	done
			#done

			echo "$allSyncFolders" \
			| while read -r sourceName sourcePath mergePath ; do
				local sourceFullPath="$MDSC_SOURCE/$sourceName/$sourcePath"
				local targetFullPath="$targetPath/$mergePath"
			
				echo "$allCloneFiles" | grep "^$sourceName $sourcePath " \
				| while read -r sourceName sourcePath sourceFileName targetFileName ; do
					rsync -rt --chmod=ug+rw "$sourceFullPath/$sourceFileName" "$targetFullPath/$targetFileName"
				done
			done
			return 0
		;;
		--to-temp)
			shift
			local tempDirectory="`mktemp -d -t "MDSC_IPF"`"
			local saveDirectory="`pwd`"
			trap "cd '$saveDirectory' ; rm -rf '$tempDirectory'" EXIT
			echo "InstallPrepareFiles: using temp: $tempDirectory" >&2
			InstallPrepareFiles --to-directory "$tempDirectory"
			echo "InstallPrepareFiles: temp prepared" >&2

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
				echo "ERROR: InstallPrepareFiles: deploy-output directory is missing: $MMDAPP/output" >&2; 
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